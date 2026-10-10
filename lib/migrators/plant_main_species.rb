# Points each plant without a main species at its root species (#404).
#
# Species#setup_main_species never set plants.main_species_id, so every
# creation path (GBIF, WCVP, corrections...) left the link empty: 52,601
# plants in production on 2026-10-10. The public /plants collection lists
# species and was unaffected, but Plant#main_species (PlantSerializer, its
# main image, its completion percentage) read nil for all of them.
#
# A plant is linked only when the answer is unambiguous:
#   - exactly one root species (main_species_id IS NULL) on the plant, or
#   - several roots, exactly one of which carries the plant's own name.
# Anything else is counted and left alone: empty plants (no species at all)
# and plants with several roots and no name match. A species already main of
# another plant is never claimed twice. Replayable; dry run by default.
module Migrators
  class PlantMainSpecies

    Result = Struct.new(:linked, :empty, :ambiguous, :already_main, :ambiguous_sample, keyword_init: true)

    def self.run(dry_run: true, limit: nil)
      result = Result.new(linked: 0, empty: 0, ambiguous: 0, already_main: 0, ambiguous_sample: [])
      scope = ::Plant.where(main_species_id: nil)
      scope = scope.limit(limit) if limit

      scope.find_each do |plant|
        root = pick_root(plant, result)
        next unless root

        if ::Plant.exists?(main_species_id: root.id)
          result.already_main += 1
          next
        end

        plant.update_columns(main_species_id: root.id) unless dry_run # rubocop:disable Rails/SkipsModelValidations
        result.linked += 1
      end

      Rails.logger.info("[PlantMainSpecies]#{' DRY RUN' if dry_run} #{result.to_h.except(:ambiguous_sample)}")
      result
    end

    def self.pick_root(plant, result)
      roots = ::Species.where(plant_id: plant.id, main_species_id: nil).to_a
      return roots.first if roots.size == 1

      if roots.empty?
        result.empty += 1 unless ::Species.exists?(plant_id: plant.id)
        return nil
      end

      named = roots.select {|s| s.scientific_name == plant.scientific_name }
      return named.first if named.size == 1

      result.ambiguous += 1
      result.ambiguous_sample << plant.scientific_name if result.ambiguous_sample.size < 20
      nil
    end
    private_class_method :pick_root

  end
end
