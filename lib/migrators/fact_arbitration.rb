# Re-applies the documented source ranking (config/traits.yml,
# docs "Data sources") to trait columns that already hold a value.
#
# Migrators::FactPromotion only fills empty columns. So a value written by the
# 2022 import, which no source defends, kept beating an active fact from a
# source the ranking puts above it: Fagus sylvatica served light 7 while TRY
# says 3 (beech is a shade tree), because the column was simply there first.
# Ingester::Species already lets a strictly stronger source replace such a
# value when it ingests; this applies the same rule to facts recorded without
# going through the ingester (the TRY import records facts and stops).
#
# For one species attribute, the column is replaced only when all of this
# holds:
#
#   - no `community` fact is active on it, as winner or as backer: a value a
#     person reviewed is never touched by a bulk job;
#   - the strongest active fact is from a single rank, strictly stronger than
#     what backs the column now. What backs it is the strongest active fact
#     holding the same value; with none (a 2022 value, traced or not), the
#     legacy rank of traits.yml. A tie is left alone, as in the ingester;
#   - that fact is corroborated (n_observations >= min_observations, nil
#     meaning "not counted") and passes the contract (plausible range,
#     allowed vocabulary, convertible to the column type), the same gates
#     FactPromotion applies before filling a gap.
#
# What happens to the value it replaces:
#
#   - an active `legacy` fact holding it (Migrators::LegacyProvenance) is
#     marked superseded, with a note naming the fact that won;
#   - a value with no fact at all gets one: source `legacy`, status
#     superseded, holding the old value, so the trail still shows it;
#   - an active fact from a real source holding it stays active. It is still
#     what that source says, and SpeciesFact keeps losing claims active (the
#     conflict list); superseded means "replaced by the same source".
#
# Written through Species#save!, not update_columns: the completion ratio
# recomputes, validations run, and the search index hears about it through
# Searchkick's queued callback. A species that cannot be saved is skipped and
# named, never forced.
#
# Replayable: once replaced, the column holds the winner's value and the
# attribute is no longer a conflict. Dry run by default.
module Migrators
  class FactArbitration

    LEGACY = Traits::LEGACY_SOURCE
    COMMUNITY = 'community'.freeze
    BATCH_SIZE = 1_000

    # One species attribute whose column disagrees with its strongest active
    # fact. `verdict` is :arbitrable when the run replaces it, otherwise the
    # reason it does not.
    Conflict = Struct.new(:species_id, :scientific_name, :attribute_name, :column_value,
                          :shown_source, :shown_rank, :backing_fact_id,
                          :winner_source, :winner_rank, :winner_fact_id, :winner_value,
                          :winner_n_observations, :winner_evidence_type,
                          :other_sources, :verdict, keyword_init: true)

    Result = Struct.new(:conflicts, :replaced, :by_verdict, :by_pair, :by_attribute,
                        :legacy_facts_superseded, :legacy_traces_created, :invalid_species,
                        keyword_init: true)

    class << self

      # attributes:       restrict to these columns (default: every trait column
      #                   except the set columns, which must be named)
      # limit:            stop after replacing values on this many species
      # min_observations: corroboration a winning fact needs (FactPromotion's)
      # dry_run:          report without writing (the default)
      # A block, when given, receives every Conflict found (to export them).
      def run(dry_run: true, attributes: nil, limit: nil,
              min_observations: FactPromotion::MIN_OBSERVATIONS, &on_conflict)
        result = Result.new(conflicts: 0, replaced: 0, by_verdict: Hash.new(0), by_pair: Hash.new(0),
                            by_attribute: Hash.new(0), legacy_facts_superseded: 0, legacy_traces_created: 0,
                            invalid_species: {})
        attrs = arbitrable_attributes(attributes)
        species_done = 0

        species_scope(attrs).find_in_batches(batch_size: BATCH_SIZE) do |batch|
          facts = ::SpeciesFact.active_status.where(species_id: batch.map(&:id), attribute_name: attrs)
            .group_by(&:species_id)

          batch.each do |species|
            break if limit && species_done >= limit

            conflicts = conflicts_for(species, facts.fetch(species.id, []), min_observations)
            species_done += 1 if settle!(species, conflicts, result, dry_run, &on_conflict)
          end
        end

        log(result, dry_run)
        result
      end

      # Trait columns: the allow-list FactPromotion uses, minus what
      # LegacyProvenance leaves out too (caches of other records, free text),
      # and minus the set columns unless asked for by name (#set_columns).
      def arbitrable_attributes(only = nil)
        all = Traits.completion_fields & ::Species.column_names
        all -= LegacyProvenance::CACHE_FIELDS + LegacyProvenance::FREE_TEXT_FIELDS
        only ? all & Array(only).map(&:to_s) : all - set_columns
      end

      # Bitmask columns hold a set (months, colours, durations), and replacing
      # a set is not the same act as replacing a value: TRY's aggregated sets
      # are built differently from the 2022 ones (flowering is often the onset
      # month alone, durations the union of every report: Trifolium repens
      # perennial -> annual, perennial). On the 2026-10-13 production copy, a
      # default run over them would have narrowed or blurred hundreds of
      # sets. They are left out of a default run and only arbitrated when a
      # caller names them.
      def set_columns
        ::Species.active_flags.keys.map(&:to_s)
      end

      # The conflicts of one species. Public so a report can be built on it.
      def conflicts_for(species, facts, min_observations = FactPromotion::MIN_OBSERVATIONS)
        facts.group_by(&:attribute_name).filter_map do |attr, attr_facts|
          conflict_for(species, attr, attr_facts, min_observations)
        end
      end

      private

      # Tallies one species' conflicts and replaces its arbitrable ones.
      # Returns true when the species was written (or would be).
      def settle!(species, conflicts, result, dry_run)
        conflicts.each do |c|
          tally(result, c)
          yield c if block_given?
        end
        winners = conflicts.select {|c| c.verdict == :arbitrable }
        winners.any? && replace!(species, winners, result, dry_run)
      end

      def species_scope(attrs)
        ::Species.where(<<~SQL.squish, attrs, ::SpeciesFact.statuses[:active]).order(:id)
          EXISTS (SELECT 1 FROM species_facts f
                  WHERE f.species_id = species.id AND f.attribute_name IN (?) AND f.status = ?)
        SQL
      end

      def conflict_for(species, attr, facts, min_observations)
        current = species.read_attribute(attr)
        return nil unless Traits.filled?(attr, current)

        ranked = facts.sort_by {|f| [Traits.priority_index(f.source, attr), f.id] }
        winner = ranked.first
        winner_value = FactPromotion.column_value(species, attr, winner.value)
        return nil if same_value?(species, attr, winner_value)

        backing = ranked.find {|f| same_value?(species, attr, FactPromotion.column_value(species, attr, f.value)) }
        shown_rank = backing ? rank(backing.source, attr) : Traits.legacy_value_priority_index(attr)

        Conflict.new(
          species_id: species.id, scientific_name: species.scientific_name, attribute_name: attr,
          column_value: display(species.public_send(attr)),
          shown_source: backing ? backing.source : 'none (2022 value, no fact)',
          shown_rank: shown_rank + 1, backing_fact_id: backing&.id,
          **winner_columns(winner, attr),
          other_sources: (ranked - [winner, backing]).map {|f| "#{f.source}=#{f.value}" }.join('; '),
          verdict: verdict(attr, ranked, winner, winner_value, shown_rank, min_observations)
        )
      end

      def winner_columns(winner, attr)
        { winner_source: winner.source, winner_rank: rank(winner.source, attr) + 1,
          winner_fact_id: winner.id, winner_value: winner.value,
          winner_n_observations: winner.n_observations, winner_evidence_type: winner.evidence_type }
      end

      # Why a conflict is or is not replaced: first whether the ranking lets
      # the winner replace the value at all, then whether the winner is a
      # value FactPromotion would accept into an empty column.
      def verdict(attr, ranked, winner, winner_value, shown_rank, min_observations)
        ranking_verdict(attr, ranked, shown_rank) ||
          contract_verdict(attr, winner, winner_value, min_observations) ||
          :arbitrable
      end

      def ranking_verdict(attr, ranked, shown_rank)
        winner, runner_up = ranked
        winner_rank = rank(winner.source, attr)
        return :community if ranked.any? {|f| f.source.casecmp?(COMMUNITY) }
        return :not_stronger if winner_rank >= shown_rank

        :tie_at_top if runner_up && rank(runner_up.source, attr) == winner_rank && runner_up.value != winner.value
      end

      def contract_verdict(attr, winner, winner_value, min_observations)
        return :low_confidence if winner.n_observations && winner.n_observations < min_observations
        return :unconvertible if winner_value.nil?
        return :implausible unless Traits.plausible?(attr, winner_value)

        :not_allowed unless Traits.allowed_value?(attr, winner.value)
      end

      def rank(source, attr)
        Traits.priority_index(source, attr)
      end

      # Column value vs a fact read back as a column value. Flags compare as
      # sets, numbers numerically (a float column holds 7.5, a fact "7.5" or
      # "7.50"), everything else as strings.
      def same_value?(species, attr, value)
        return false if value.nil?

        current = species.public_send(attr)
        case current
        when ActiveFlag::Value then current.to_a.map(&:to_sym).sort == Array(value).map(&:to_sym).sort
        when Numeric then value.is_a?(Numeric) && (current.to_f - value.to_f).abs < 1e-6
        else current.to_s == value.to_s
        end
      end

      def display(value)
        value.is_a?(ActiveFlag::Value) ? value.to_a.join('|') : value.to_s
      end

      def tally(result, conflict)
        result.conflicts += 1
        result.by_verdict[conflict.verdict] += 1
        result.by_pair["#{conflict.shown_source} -> #{conflict.winner_source} (#{conflict.verdict})"] += 1
        result.by_attribute["#{conflict.attribute_name} (#{conflict.verdict})"] += 1
      end

      # Returns true when the species was written (or would be, in a dry run).
      def replace!(species, winners, result, dry_run)
        old_values = assign_winners!(species, winners)

        unless dry_run
          ::Species.transaction do
            species.save!
            winners.each {|c| retire_old_value!(species, c, old_values[c.attribute_name], result) }
          end
        end
        result.replaced += winners.size
        true
      rescue ActiveRecord::RecordInvalid => e
        # Same policy as FactPromotion: a record already invalid for reasons of
        # its own is skipped and named, not saved with validate: false.
        result.invalid_species[species.id] = e.record.errors.full_messages.to_sentence
        result.by_verdict[:arbitrable] -= winners.size
        result.by_verdict[:invalid_species] += winners.size
        species.restore_attributes
        false
      end

      # Sets each winning value on the record; returns the values replaced, by
      # attribute, in the form a fact records them (flags by name).
      def assign_winners!(species, winners)
        winners.to_h do |c|
          attr = c.attribute_name
          old_value = species.public_send(attr)
          old_value = old_value.to_a.join('|') if old_value.is_a?(ActiveFlag::Value)
          species.public_send("#{attr}=", FactPromotion.column_value(species, attr, c.winner_value))
          [attr, old_value]
        end
      end

      def retire_old_value!(species, conflict, old_value, result)
        note = "replaced by #{conflict.winner_source} fact ##{conflict.winner_fact_id} " \
               "(#{conflict.winner_value}), stronger source per config/traits.yml (FactArbitration)"
        backing = conflict.backing_fact_id && ::SpeciesFact.find(conflict.backing_fact_id)

        if backing&.source == LEGACY
          backing.update!(status: :superseded, notes: [backing.notes, note].compact.join("\n"))
          result.legacy_facts_superseded += 1
        elsif backing.nil?
          ::SpeciesFact.create!(
            species: species, attribute_name: conflict.attribute_name, source: LEGACY,
            value: old_value.to_s, value_numeric: old_value.is_a?(Numeric) ? old_value : nil,
            unit: Traits.field(conflict.attribute_name)&.dig('unit'), status: :superseded,
            notes: "#{LegacyProvenance::NOTE}\n#{note}"
          )
          result.legacy_traces_created += 1
        end
      end

      def log(result, dry_run)
        prefix = dry_run ? '[FactArbitration][dry-run]' : '[FactArbitration]'
        Rails.logger.info("#{prefix} #{result.conflicts} conflicts, #{result.replaced} values replaced")
        result.by_verdict.each {|verdict, n| Rails.logger.info("#{prefix}   #{verdict}: #{n}") }
        result.invalid_species.each {|id, error| Rails.logger.info("#{prefix}   invalid species #{id}: #{error}") }
      end

    end
  end
end
