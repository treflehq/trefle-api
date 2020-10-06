module Migrators
  class SynonymsDuplicates

    def self.run
      Species.joins(
        "INNER JOIN synonyms ON species.scientific_name = synonyms.name AND synonyms.id IS NOT NULL and synonyms.record_type = 'Species'
      ").each do |sp|
        migrate_species!(sp)
      end
    end

    # rubocop:todo Naming/MethodParameterName
    def self.migrate_species!(sp) # rubocop:todo Metrics/PerceivedComplexity # rubocop:todo Naming/MethodParameterName # rubocop:todo Naming/MethodParameterName
      to_merge = sp
      synonyms = Synonym.where(name: to_merge.scientific_name)

      raise "Multiple synonyms !" if synonyms.pluck(:record_id).uniq.count > 1
      
      good_species = synonyms.first.record

      if good_species && to_merge
        ::Utils::Merger.new([to_merge.id], good_species.id).merge!
      end
    end

  end
end
