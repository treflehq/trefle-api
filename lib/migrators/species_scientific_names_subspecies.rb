module Migrators
  class SpeciesScientificNamesSubspecies

    def self.run
      ::Species.where("array_length(string_to_array(scientific_name, ' '), 1) > 2").each do |p|

        next if (p.scientific_name =~ /(\s[\w]+) (var|subsp)\.\1/).nil?

        good_species = ::Species.find_by(scientific_name: p.scientific_name.gsub(/(\s[\w]+)( (var|subsp)\.\1)/, '\1'))

        if good_species
          ::Utils::Merger.new([p.id], good_species.id).merge!
        else
          old_name = p.scientific_name
          p.scientific_name = p.scientific_name.gsub(/(\s[\w]+)( (var|subsp)\.\1)/, '\1')
          p.rank = :species
          p.save
          Synonym.where(record: p, name: old_name, author: p.author).first_or_create
        end
      end
      true
    end
  end
end
