module Quality
  # Writes the dated data-quality rows (see DataQualitySnapshot):
  # fill rate / implausible count / conflict count per trait field, plus
  # aggregates per rank and per source. One species-table scan.
  class Snapshot

    def self.run!(date: Time.zone.today)
      new(date).run!
    end

    def initialize(date = Time.zone.today)
      @date = date
    end

    def run!
      # Hard whitelist: field names get interpolated in SQL, only actual
      # species columns (as declared in config/traits.yml) may pass.
      fields = Traits.completion_fields & Species.column_names
      total = Species.count
      row = fill_rates_row(fields)
      conflicts_by_attr = conflict_counts

      DataQualitySnapshot.transaction do
        write_field_rows!(fields, total, row, conflicts_by_attr)
        write_global_aggregate!(fields, total, row, conflicts_by_attr)
        write_rank_rows!
        write_source_rows!
      end

      { date: @date, species_count: total, fields_count: fields.length }
    end

    private

    # SQL expression counting a field as "filled", honouring zero_means_empty
    # and blank strings (mirrors Traits.filled?)
    def filled_expression(name)
      column = Species.columns_hash[name]

      if Traits.field(name)['zero_means_empty']
        "COUNT(NULLIF(#{name}, 0))"
      elsif %i[string text].include?(column.type)
        "COUNT(NULLIF(BTRIM(#{name}), ''))"
      else
        "COUNT(#{name})"
      end
    end

    def implausible_expression(name)
      range = Traits.field(name)['plausible_range']
      return '0' unless range

      "SUM(CASE WHEN #{name} IS NOT NULL AND (#{name} < #{range[0]} OR #{name} > #{range[1]}) THEN 1 ELSE 0 END)"
    end

    def fill_rates_row(fields)
      selects = fields.flat_map do |f|
        ["#{filled_expression(f)} AS filled_#{f}", "#{implausible_expression(f)} AS implausible_#{f}"]
      end
      ActiveRecord::Base.connection.select_one("SELECT #{selects.join(', ')} FROM species")
    end

    # (species, attribute) pairs where active facts disagree, per attribute
    def conflict_counts
      ActiveRecord::Base.connection.select_all(<<~SQL).to_a.to_h {|c| [c['attribute_name'], c['conflict_count'].to_i] }
        SELECT attribute_name, COUNT(*) AS conflict_count FROM (
          SELECT species_id, attribute_name
          FROM species_facts
          WHERE status = 0
          GROUP BY species_id, attribute_name
          HAVING COUNT(DISTINCT value) > 1
        ) c GROUP BY attribute_name
      SQL
    end

    def write_field_rows!(fields, total, row, conflicts_by_attr)
      fields.each do |f|
        DataQualitySnapshot.find_or_initialize_by(
          snapshot_on: @date, dimension: 'global', dimension_value: nil, attribute_name: f
        ).update!(
          species_count: total,
          filled_count: row["filled_#{f}"].to_i,
          implausible_count: row["implausible_#{f}"].to_i,
          conflict_count: conflicts_by_attr.fetch(f, 0)
        )
      end
    end

    def write_global_aggregate!(fields, total, row, conflicts_by_attr)
      DataQualitySnapshot.find_or_initialize_by(
        snapshot_on: @date, dimension: 'global', dimension_value: nil, attribute_name: nil
      ).update!(
        species_count: total,
        filled_count: fields.sum {|f| row["filled_#{f}"].to_i },
        implausible_count: fields.sum {|f| row["implausible_#{f}"].to_i },
        conflict_count: conflicts_by_attr.values.sum,
        details: {
          fields_count: fields.length,
          avg_completion_ratio: Species.average(:completion_ratio)&.round(1)&.to_f
        }
      )
    end

    def write_rank_rows!
      Species.group(:rank).count.each do |rank, count|
        DataQualitySnapshot.find_or_initialize_by(
          snapshot_on: @date, dimension: 'rank', dimension_value: rank || 'unknown', attribute_name: nil
        ).update!(
          species_count: count,
          details: { avg_completion_ratio: Species.where(rank: rank).average(:completion_ratio)&.round(1)&.to_f }
        )
      end
    end

    def write_source_rows!
      SpeciesFact.group(:source, :status).count.group_by {|(source, _), _| source }.each do |source, rows|
        by_status = rows.to_h {|(_, status), count| [status, count] }
        DataQualitySnapshot.find_or_initialize_by(
          snapshot_on: @date, dimension: 'source', dimension_value: source, attribute_name: nil
        ).update!(
          species_count: by_status.values.sum,
          filled_count: by_status.fetch('active', 0),
          implausible_count: by_status.fetch('rejected', 0),
          details: by_status
        )
      end
    end

  end
end
