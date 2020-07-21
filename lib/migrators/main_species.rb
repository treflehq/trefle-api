module Migrators
  class MainSpecies

    def self.run
      Species.find_each do |sp|
        next if sp.main_species_id

        next if sp.has_root_name?

        main_spec = Species.find_by_scientific_name(sp.root_name)
        return unless main_spec

        puts sp.errors.messages unless sp.update(main_species_id: main_spec.id)
      end
    end
  end
end
