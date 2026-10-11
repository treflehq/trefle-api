# A species may hold the same zone twice in species_distributions (1,556 rows
# on the 2026-10-10 dump), from crawls that never checked. One row stays per
# (species, zone): the one with the strongest establishment (native before
# introduced, then doubtful, absent, extinct), lowest id on a tie. The zone
# counters are then recomputed. Replayable; dry run by default (#419).
module Migrators
  class DistributionDuplicates

    Result = Struct.new(:duplicates, :removed, keyword_init: true)

    def self.run(dry_run: true)
      ids = duplicate_ids
      result = Result.new(duplicates: ids.size, removed: 0)

      unless dry_run
        result.removed = ::SpeciesDistribution.where(id: ids).delete_all
        ::SpeciesDistribution.counter_culture_fix_counts if result.removed.positive?
      end

      Rails.logger.info("[DistributionDuplicates]#{' DRY RUN' if dry_run} #{result.to_h}")
      result
    end

    def self.duplicate_ids
      ::SpeciesDistribution.connection.select_values(<<~SQL.squish)
        SELECT DISTINCT a.id FROM species_distributions a
        JOIN species_distributions b ON a.species_id = b.species_id AND a.zone_id = b.zone_id AND a.id <> b.id
        WHERE coalesce(a.establishment, 99) > coalesce(b.establishment, 99)
           OR (coalesce(a.establishment, 99) = coalesce(b.establishment, 99) AND a.id > b.id)
      SQL
    end
    private_class_method :duplicate_ids

  end
end
