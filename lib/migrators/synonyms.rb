module Migrators
  class Synonyms

    def self.run
      Species.where(status: 'Synonym').find_in_batches.with_index.each do |sps, i|
        puts "Batching species group #{i}"
        sps.each do |sp|
          migrate_species!(sp)
        end
      end
    end

    # rubocop:todo Naming/MethodParameterName
    def self.migrate_species!(sp) # rubocop:todo Metrics/PerceivedComplexity # rubocop:todo Naming/MethodParameterName # rubocop:todo Naming/MethodParameterName
      if sp.synonym_of_id == sp.id || sp.main_species_id == sp.id
        unknowise_species!(sp)
      else
        good_sp = sp.synonym_of || sp.main_species
        if good_sp
          synonym = Synonym.where(name: sp.scientific_name, record: good_sp).first_or_create(
            author: sp.author
          )
          puts "Valid ? => #{synonym.valid?}"
          puts "Errors ? => #{synonym.errors.messages}" if synonym.errors.any?
          if synonym.valid?
            sp.foreign_sources_plants.map do |fsp|
              fsp.update!(record: synonym, species_id: nil)
            end
            puts "FS: #{sp.foreign_sources_plants.count}"
            puts "Images: #{sp.species_images.count}"
          else
            unknowise_species!(sp)
          end
        end
        sp.reload.destroy
      end
    end
    # rubocop:enable Naming/MethodParameterName

    def self.unknowise_species!(sp) # rubocop:todo Naming/MethodParameterName
      sp.update(
        status: 'Unknown',
        synonym_of_id: sp.synonym_of_id == sp.id ? nil : sp.synonym_of_id,
        main_species_id: sp.main_species_id == sp.id ? nil : sp.main_species_id
      )
    end

  end
end
