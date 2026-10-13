# An autonym (an infraspecific name whose last epithet repeats the species
# epithet: "Festuca gautieri subsp. gautieri") is established automatically
# by the Code and carries no authorship (ICN Art. 26). 4,320 of ours came with
# an author anyway, copied from the species or from the taxon that created the
# autonym by the 2022 import; WCVP confirms an empty authorship for 3,062 of
# them. The author column is blanked, the year is kept (it dates the
# publication that established the autonym), and the removal leaves a trace:
# the active author facts are marked rejected with the reason, and a record
# that had no fact gets a rejected `legacy` fact holding the removed value.
#
# The column is written with update_columns on purpose: the author is not
# part of the name, so nothing nomenclatural needs re-validation (the token is
# computed from scientific_name only), while a plain save would run every
# before_validation callback and the token uniqueness check and could stop a
# batch on a record whose problem has nothing to do with its author. Records
# with a pending correction are skipped: the reviewer's decision comes first.
# Replayable; dry run by default.
module Migrators
  class AutonymAuthors

    AUTONYM = '^(\S+) (\S+) (subsp|var|f)\. \2$'.freeze
    REASON = 'autonym: no authorship under the Code'.freeze

    Result = Struct.new(:autonyms, :blanked, :facts_rejected, :legacy_traced, :skipped_pending_correction,
                        keyword_init: true)

    def self.scope
      ::Species.where('scientific_name ~ ?', AUTONYM).where.not(author: [nil, ''])
    end

    def self.pending_ids
      ::RecordCorrection.pending_change_status.where(record_type: 'Species').select(:record_id)
    end

    def self.run(dry_run: true)
      skipped = scope.where(id: pending_ids).count
      result = Result.new(autonyms: scope.count - skipped, blanked: 0, facts_rejected: 0, legacy_traced: 0,
                          skipped_pending_correction: skipped)

      unless dry_run
        scope.where.not(id: pending_ids).find_each do |species|
          facts = species.species_facts.active_status.for_attribute('author').to_a
          facts.each do |fact|
            fact.update!(status: :rejected, notes: [fact.notes, REASON].compact.join("\n"))
            result.facts_rejected += 1
          end
          if facts.empty?
            ::SpeciesFact.create!(species: species, attribute_name: 'author', source: 'legacy',
                                  value: species.author, status: :rejected, notes: REASON)
            result.legacy_traced += 1
          end
          species.update_columns(author: nil) # rubocop:disable Rails/SkipsModelValidations
          result.blanked += 1
        end
      end

      Rails.logger.info("[AutonymAuthors]#{' DRY RUN' if dry_run} #{result.to_h}")
      result
    end

  end
end
