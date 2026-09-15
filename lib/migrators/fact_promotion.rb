# Fills an empty species trait column from the strongest active SpeciesFact
# that claims it (trefle-api#328).
#
# The import pipelines deliberately never write trait columns: they record
# facts with provenance and stop there (see Crawlers::Try::Import). This is the
# other half — the step that lets a sourced claim actually reach the API.
#
# Three rules, in order of how much damage breaking them would do:
#
#   1. An empty column only. A filled value is never overwritten, whatever its
#      source and whatever the fact says. Disagreements are a human's call and
#      go through Checks::FactDivergence -> the corrections queue, not through
#      a bulk job.
#   2. Only attributes in the traits.yml contract. Fact-only attributes —
#      human usage types (#18), the two Ellenberg indicators marked
#      `promoted: false` (#14) — are not in it and so cannot be promoted by
#      construction, not merely by omission from a list here.
#   3. Only corroborated facts. A fact whose n_observations is 1 rests on a
#      single measurement; it stays visible as a fact and is not projected.
#      A nil n_observations is "not counted", not "counted once" — mapping
#      tables carry no observation count — so it is not treated as weak.
#
# Replayable: a column filled by a previous run is no longer empty, so the
# next run skips it. Re-running after new facts arrive promotes only the gaps
# that are still gaps.
module Migrators
  class FactPromotion

    # A fact resting on one measurement is recorded but not projected.
    MIN_OBSERVATIONS = 2

    Result = Struct.new(:promoted, :skipped, :per_attribute, :rejected, keyword_init: true)

    class << self

      # source:  restrict to one source ('try'), or nil for every source
      # dry_run: compute and report without writing (the default: this job
      #          touches the columns the API serves, so writing is opt-in)
      def run(source: nil, dry_run: true, limit: nil)
        result = Result.new(promoted: 0, skipped: 0, per_attribute: Hash.new(0), rejected: Hash.new(0))

        candidates(source, limit).group_by(&:species_id).each do |species_id, facts|
          promote_species!(species_id, facts, result, dry_run)
        end

        log(result, dry_run)
        result
      end

      private

      # Active facts on contract attributes, strongest source first so the
      # per-attribute pick below is just `first`.
      def candidates(source, limit)
        scope = SpeciesFact.active_status.where(attribute_name: promotable_attributes)
        scope = scope.where(source: source) if source
        scope = scope.limit(limit) if limit
        scope.to_a.sort_by {|f| Traits.priority_index(f.source) }
      end

      # The contract is the allow-list. Fact-only attributes are absent from
      # traits.yml, so they never appear here -- see rule 2.
      def promotable_attributes
        @promotable_attributes ||= Traits.completion_fields & Species.column_names
      end

      def promote_species!(species_id, facts, result, dry_run)
        species = Species.find_by(id: species_id)
        return unless species

        facts.group_by(&:attribute_name).each do |attr, attr_facts|
          fact = attr_facts.first # strongest source, candidates is sorted
          next result.skipped += 1 unless promotable?(species, attr, fact, result)

          value = column_value(species, attr, fact.value)
          next result.skipped += 1 if value.nil?

          species.send("#{attr}=", value)
          result.per_attribute[attr] += 1
          result.promoted += 1
        end

        # Saving (not update_columns) so the completion ratio recomputes
        # through the existing before_save hook.
        species.save! if !dry_run && species.changed?
      end

      def promotable?(species, attr, fact, result)
        return reject(result, :filled) if Traits.filled?(attr, species.read_attribute(attr))
        return reject(result, :low_confidence) if fact.n_observations && fact.n_observations < MIN_OBSERVATIONS
        return reject(result, :implausible) unless Traits.plausible?(attr, fact.value)
        return reject(result, :not_allowed) unless Traits.allowed_value?(attr, fact.value)

        true
      end

      def reject(result, reason)
        result.rejected[reason] += 1
        false
      end

      # The inverse of Ingester::Species#fact_value: a flag column was stored
      # as "a|b|c", everything else as its own to_s. Returns nil when the
      # stored string cannot be turned back into a value the column accepts,
      # so a malformed fact is skipped rather than raising mid-run.
      def column_value(species, attr, raw)
        return nil if raw.nil? || raw.strip.empty?

        current = species.send(attr)
        return raw.split('|').map(&:strip).reject(&:empty?).map(&:to_sym) if current.is_a?(ActiveFlag::Value)
        return raw if species.class.defined_enums.key?(attr) && species.class.defined_enums[attr].key?(raw)
        return nil if species.class.defined_enums.key?(attr)

        cast(species, attr, raw)
      end

      def cast(species, attr, raw)
        case species.class.columns_hash[attr]&.type
        when :integer then Integer(raw, exception: false)
        when :float, :decimal then Float(raw, exception: false)
        when :boolean then ActiveModel::Type::Boolean.new.cast(raw)
        else raw
        end
      end

      def log(result, dry_run)
        prefix = dry_run ? '[FactPromotion][dry-run]' : '[FactPromotion]'
        Rails.logger.info("#{prefix} promoted #{result.promoted}, skipped #{result.skipped}")
        result.rejected.each {|reason, n| Rails.logger.info("#{prefix}   skipped #{n} (#{reason})") }
        result.per_attribute.sort_by {|_, n| -n }.each {|attr, n| Rails.logger.info("#{prefix}   #{attr}: #{n}") }
      end

    end
  end
end
