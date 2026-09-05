module Quality
  # Reads the dated snapshots back as a progression, so it is possible to see
  # whether the dataset is actually improving rather than only where it stands.
  #
  #   Quality::Evolution.new(days: 30).series      # one row per day
  #   Quality::Evolution.new(days: 30).field_moves # what gained and what lost
  class Evolution

    Point = Struct.new(:date, :species_count, :filled_count, :fields_count,
                       :avg_completion, :implausible_count, :conflict_count,
                       keyword_init: true) do
      # Share of the measurable surface that is actually filled: filled cells
      # over the cells that exist. A steadier number than the average ratio,
      # which moves when applicability changes.
      def fill_rate
        return nil if species_count.to_i.zero? || fields_count.to_i.zero?

        (filled_count.to_f / (species_count * fields_count) * 100).round(2)
      end
    end

    Move = Struct.new(:field, :from, :to, keyword_init: true) do
      def delta
        to.to_i - from.to_i
      end
    end

    def initialize(days: 30)
      @days = days
    end

    # One point per day, oldest first.
    def series
      aggregates.map do |row|
        Point.new(
          date: row.snapshot_on,
          species_count: row.species_count,
          filled_count: row.filled_count,
          fields_count: row.details&.dig('fields_count'),
          avg_completion: row.details&.dig('avg_completion_ratio'),
          implausible_count: row.implausible_count,
          conflict_count: row.conflict_count
        )
      end
    end

    # Change in filled_count per field between the first and last snapshot in
    # the window. Negative moves matter as much as positive ones: a field that
    # loses values is a regression worth seeing.
    def field_moves
      first_date, last_date = boundary_dates
      return [] if first_date.nil? || first_date == last_date

      first = counts_by_field(first_date)
      last = counts_by_field(last_date)

      moves = (first.keys | last.keys).filter_map do |field|
        move = Move.new(field: field, from: first[field].to_i, to: last[field].to_i)
        move unless move.delta.zero?
      end

      moves.sort_by {|m| -m.delta.abs }
    end

    def window
      boundary_dates
    end

    private

    def scope
      DataQualitySnapshot.where(dimension: 'global')
        .where(snapshot_on: @days.days.ago.to_date..)
    end

    def aggregates
      @aggregates ||= scope.where(attribute_name: nil).order(:snapshot_on).to_a
    end

    def boundary_dates
      dates = aggregates.map(&:snapshot_on)
      [dates.first, dates.last]
    end

    def counts_by_field(date)
      scope.where(snapshot_on: date).where.not(attribute_name: nil)
        .pluck(:attribute_name, :filled_count).to_h
    end

  end
end
