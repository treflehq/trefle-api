# Provenance recording (2.1.0) only covers values written after it existed.
# Everything the 2022 import left in the species columns is served with no
# fact behind it: the provenance endpoint has nothing to say about it, and
# source arbitration has to guess (Traits.legacy_value_priority_index) what
# defends the value. This migrator gives every such served value an active
# `legacy` fact, so that a reader can tell "no source recorded" from "not
# yet looked at", and so that a later correction has a fact to supersede or
# reject rather than a bare column.
#
# What counts as a served value: the trait fields of config/traits.yml in the
# descriptive, morphology, phenology, ecology and cultivation categories, with
# a column that is filled in the sense of Traits.filled? — minus three
# deliberate exclusions:
#   - booleans at false. On edible/vegetable, false is the column default on
#     494k rows, not a value anybody recorded (#351); the other boolean
#     columns are small enough that a false is counted and left for a human
#     call rather than traced blindly.
#   - bitmasks at 0 and strings at '' (undocumented, not a value).
#   - caches of other records that carry their own provenance:
#     main_image_url (species_images have a source), family_common_name (the
#     family's name).
#   - the free-text descriptive columns, observations (a locality note:
#     "Oregon to California") and common_name: not trait values, and at 379k
#     rows they would dwarf the real traces with noise.
#
# ph_minimum/ph_maximum: the 2022 import converted Baseflor soil reaction
# classes (an ordinal, Ellenberg R) into pH intervals, which the public docs
# say is not done. A pair matching one of those bins exactly is traced with a
# note saying so and the weakest evidence type, inferred: an interval imputed
# from a class, not a measurement. The values are not removed here.
#
# Replayable (an existing active legacy fact is skipped by the partial unique
# index); dry run by default.
module Migrators
  class LegacyProvenance

    SOURCE = 'legacy'.freeze
    NOTE = 'value present before provenance tracking (2022 import), no source recorded'.freeze
    BASEFLOR_NOTE = 'derived from a Baseflor soil reaction class by the 2022 import, a class not a measurement'.freeze
    # (ph_minimum, ph_maximum) intervals the 2022 import mapped Baseflor's nine
    # soil reaction classes onto.
    BASEFLOR_PH_BINS = [[3, 4], [4, 4.5], [4.5, 5], [5, 5.5], [5.5, 6.5], [6.5, 7], [7, 7.5], [7.5, 8], [8, 9]].freeze
    PH_FIELDS = %w[ph_minimum ph_maximum].freeze

    CATEGORIES = %w[descriptive morphology phenology ecology cultivation].freeze
    # Caches of other records' data, which carry their own provenance.
    CACHE_FIELDS = %w[main_image_url family_common_name].freeze
    # Free text, not trait values: a locality note is not provenance-bearing
    # data, and these two alone would be 379k rows next to 62k real traces.
    FREE_TEXT_FIELDS = %w[observations common_name].freeze
    BATCH_SIZE = 5_000

    Result = Struct.new(:facts_created, :by_field, :baseflor_ph_pairs, :skipped_false_booleans, keyword_init: true)

    def self.fields
      Traits.fields.select {|name, spec| CATEGORIES.include?(spec['category']) && ::Species.column_names.include?(name) }
        .keys - CACHE_FIELDS - FREE_TEXT_FIELDS
    end

    def self.run(dry_run: true)
      result = Result.new(facts_created: 0, by_field: {}, baseflor_ph_pairs: 0, skipped_false_booleans: {})

      fields.each do |field|
        count = scope_for(field).count
        result.by_field[field] = count if count.positive?
        falses = false_booleans(field)
        result.skipped_false_booleans[field] = falses if falses.positive?
      end
      result.baseflor_ph_pairs = PH_FIELDS.sum {|field| scope_for(field).where(baseflor_pairs_sql).count }
      result.facts_created = result.by_field.values.sum

      result.facts_created = fields.sum {|field| trace!(field) } unless dry_run

      Rails.logger.info("[LegacyProvenance]#{' DRY RUN' if dry_run} #{result.to_h}")
      result
    end

    # Species serving a value of this field from the column with no active
    # fact behind it.
    def self.scope_for(field)
      scope = ::Species.where.not(field => nil)
      scope = case ::Species.columns_hash[field].type
              when :boolean then scope.where(field => true)
              when :string, :text then scope.where.not(field => '')
              else Traits.field(field)['zero_means_empty'] ? scope.where.not(field => 0) : scope
              end
      scope.where(<<~SQL.squish, field, ::SpeciesFact.statuses[:active])
        NOT EXISTS (SELECT 1 FROM species_facts f
                    WHERE f.species_id = species.id AND f.attribute_name = ? AND f.status = ?)
      SQL
    end

    def self.false_booleans(field)
      return 0 unless ::Species.columns_hash[field].type == :boolean

      ::Species.where(field => false).where(<<~SQL.squish, field, ::SpeciesFact.statuses[:active]).count
        NOT EXISTS (SELECT 1 FROM species_facts f
                    WHERE f.species_id = species.id AND f.attribute_name = ? AND f.status = ?)
      SQL
    end

    def self.baseflor_pairs_sql
      pairs = BASEFLOR_PH_BINS.map {|min, max| "(#{min}, #{max})" }.join(', ')
      "(ph_minimum, ph_maximum) IN (#{pairs})"
    end

    def self.baseflor_pair?(species)
      BASEFLOR_PH_BINS.include?([species.ph_minimum, species.ph_maximum])
    end

    # Inserts the legacy facts of one field in batches. Returns the number of
    # rows inserted (a replay finds its rows already there and inserts none).
    def self.trace!(field)
      inserted = 0
      scope_for(field).select(:id, field, *PH_FIELDS).find_in_batches(batch_size: BATCH_SIZE) do |species|
        rows = species.map {|s| row_for(s, field) }
        inserted += ::SpeciesFact.insert_all(rows).length if rows.any? # rubocop:disable Rails/SkipsModelValidations
      end
      inserted
    end

    def self.row_for(species, field)
      raw = species.public_send(field)
      baseflor = PH_FIELDS.include?(field) && baseflor_pair?(species)
      {
        species_id: species.id,
        attribute_name: field,
        source: SOURCE,
        value: fact_value(raw),
        value_numeric: raw.is_a?(Numeric) ? raw : nil,
        unit: Traits.field(field)['unit'],
        evidence_type: ::SpeciesFact.evidence_types[baseflor ? :inferred : :reported],
        status: ::SpeciesFact.statuses[:active],
        notes: baseflor ? "#{NOTE}\n#{BASEFLOR_NOTE}" : NOTE
      }
    end

    # Same convention as the ingester: a bitmask is recorded by its flag names,
    # not by an integer that means nothing on its own.
    def self.fact_value(raw)
      return raw.to_a.join('|') if raw.is_a?(ActiveFlag::Value)

      raw.to_s
    end

  end
end
