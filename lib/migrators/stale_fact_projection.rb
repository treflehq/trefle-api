# A trait column is a projection of a sourced fact (Migrators::FactPromotion).
# When that fact is later superseded or rejected -- a re-import that read the
# source correctly, a value a human struck out -- the column keeps the old
# value, because promotion fills gaps and never overwrites. The 2026-10 TRY
# phenology fix is the case at hand (trefle-crawlers#55): dataset 174 was
# read as weeks of the year, so some 1,400 `bloom_months` masks said
# January-March where the Ecological Flora says April-July, and the columns
# promoted from them would have outlived the correction.
#
# This empties a flag column whose value is exactly the mask of one of the
# source's superseded or rejected facts on that attribute -- only those citing
# one TRY dataset when one is named -- and whose active fact, if any, says
# something else. The column is a gap again, and FactPromotion refills it from
# the current fact under its own rules (corroboration, plausibility). A column
# equal to the active fact is current and kept; one equal to no fact of the
# source came from elsewhere and is not touched. The superseded or rejected
# fact is the trail: it says what the column held and why it went.
# Replayable; dry run by default.
module Migrators
  class StaleFactProjection

    Result = Struct.new(:candidates, :reset, :kept_current, :not_from_source, :already_empty, :unconvertible,
                        keyword_init: true)

    def self.run(attribute: 'bloom_months', source: 'try', dataset: 174, dry_run: true)
      new(attribute, source, dataset).run(dry_run: dry_run)
    end

    def initialize(attribute, source, dataset)
      @attribute = attribute.to_s
      @source = source
      @dataset = dataset&.to_s
      @definition = ::Species.active_flags[@attribute.to_sym]
      raise ArgumentError, "#{@attribute} is not a flag column of Species" unless @definition
    end

    def run(dry_run: true)
      result = Result.new(candidates: 0, reset: 0, kept_current: 0, not_from_source: 0, already_empty: 0,
                          unconvertible: 0)
      stale_facts.group_by(&:species_id).each do |species_id, facts|
        species = ::Species.find_by(id: species_id)
        next unless species

        result.candidates += 1
        settle(species, facts, result, dry_run)
      end
      log(result, dry_run)
      result
    end

    private

    # Superseded and rejected facts of the source on the attribute, citing the
    # dataset when one is named. A TRY fact's notes list its datasets ("TRY 7.0
    # datasets 4, 174"); the list is read as a list, not matched as a
    # substring, so 17 is not 174 and the "7" of the release is not a dataset.
    def stale_facts
      facts = ::SpeciesFact.where(attribute_name: @attribute, source: @source).where.not(status: :active).to_a
      return facts unless @dataset

      facts.select {|fact| datasets(fact).include?(@dataset) }
    end

    def datasets(fact)
      fact.notes.to_s[/datasets?\s+([\d,\s]+)/, 1].to_s.split(',').map(&:strip)
    end

    def settle(species, facts, result, dry_run)
      column = species.read_attribute(@attribute).to_i
      return result.already_empty += 1 if column.zero?

      current = species.species_facts.active_status.for_attribute(@attribute).find_by(source: @source)
      return result.kept_current += 1 if current && mask(current.value) == column

      masks = facts.map {|fact| mask(fact.value) }
      result.unconvertible += masks.count(&:nil?)
      return result.not_from_source += 1 unless masks.include?(column)

      reset(species) unless dry_run
      result.reset += 1
    end

    # Structural: the column goes back to "not filled", nothing else on the
    # record changes. Promotion then saves through the model (completion
    # ratio, index); a record it does not refill is reindexed here so the
    # search filter stops matching the struck value.
    def reset(species)
      species.update_columns(@attribute => 0) # rubocop:disable Rails/SkipsModelValidations
      species.reindex(mode: :queue) if ::Searchkick.callbacks?
    end

    # The mask a fact's flag list projects to, read the way FactPromotion
    # reads it ("a|b" or "a, b"); nil when a flag is unknown to the column.
    def mask(raw)
      flags = raw.to_s.split(/[|,]/).map(&:strip).reject(&:empty?).map(&:to_sym)
      return nil if flags.empty? || (flags - @definition.maps.keys).any?

      @definition.to_i(flags)
    end

    def log(result, dry_run)
      scope = "#{@attribute} from #{@source}#{" (dataset #{@dataset})" if @dataset}"
      Rails.logger.info("[StaleFactProjection]#{' DRY RUN' if dry_run} #{scope} #{result.to_h}")
    end

  end
end
