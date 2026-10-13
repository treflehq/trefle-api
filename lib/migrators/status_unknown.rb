# 29,064 species have no taxonomic status at all (NULL), which the API serves
# as null next to the four real values of the enum (accepted, unknown,
# rejected, doubtful). NULL and `unknown` mean the same thing here: nobody
# has said. They become `unknown`, so the column has one way of saying it and
# the reference sources (WFO, WCVP) can fill in the ones they know later.
#
# A NULL status next to an active `status` fact should not exist (the fact
# should have been projected); such records are counted and left alone for a
# look, not papered over. update_all on purpose: no callback has anything to
# recompute from a status. Replayable; dry run by default.
module Migrators
  class StatusUnknown

    Result = Struct.new(:set_unknown, :skipped_with_status_fact, keyword_init: true)

    def self.scope
      ::Species.where(status: nil)
    end

    def self.with_status_fact
      scope.where(id: ::SpeciesFact.active_status.for_attribute('status').select(:species_id))
    end

    def self.run(dry_run: true)
      skipped = with_status_fact.count
      result = Result.new(set_unknown: scope.count - skipped, skipped_with_status_fact: skipped)

      unless dry_run
        result.set_unknown = scope.where.not(id: with_status_fact.select(:id))
          .update_all(status: ::Species.statuses[:unknown]) # rubocop:disable Rails/SkipsModelValidations
      end

      Rails.logger.info("[StatusUnknown]#{' DRY RUN' if dry_run} #{result.to_h}")
      result
    end

  end
end
