module Migrators
  class PlantScientificNames

    def self.run
      Plant.where("array_length(string_to_array(scientific_name, ' '), 1) > 2").each do |p|
        rname = Species.root_scientific_name(p.scientific_name)
        ms = p.main_species

        next if rname == p.scientific_name

        good_species = Species.where(scientific_name: rname).first

        ms.update(main_species: good_species, plant_id: good_species.plant_id) if good_species && ms
        p.reload.destroy

      end
    end
  end
end
