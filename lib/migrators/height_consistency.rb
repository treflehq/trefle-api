# A maximum height below the average height of the same record is impossible
# (530 species on the 2026-10-10 dump, mostly a TRY promotion that read the
# two statistics off different observation sets). The maximum is the suspect
# value: the mean is the better-supported statistic. The column is emptied
# and the active facts behind it are marked rejected with the reason, so the
# provenance trail says why the value is gone. Replayable; dry run by
# default (#419).
module Migrators
  class HeightConsistency

    Result = Struct.new(:species, :facts_rejected, keyword_init: true)

    def self.run(dry_run: true)
      scope = ::Species.where('average_height_cm > maximum_height_cm')
      result = Result.new(species: scope.count, facts_rejected: 0)

      unless dry_run
        scope.find_each do |species|
          reason = "below the average height (#{species.average_height_cm} cm) of the same record"
          species.species_facts.active_status.for_attribute('maximum_height_cm').find_each do |fact|
            fact.update!(status: :rejected, notes: [fact.notes, reason].compact.join("\n"))
            result.facts_rejected += 1
          end
          species.update_columns(maximum_height_cm: nil) # rubocop:disable Rails/SkipsModelValidations
        end
      end

      Rails.logger.info("[HeightConsistency]#{' DRY RUN' if dry_run} #{result.to_h}")
      result
    end

  end
end
