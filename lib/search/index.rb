# Will index a species
module Search
  module Index
    def self.add_species!(species)
      Search.instance.with do |conn|
        conn.index('species').add_or_replace_documents(to_document(species))
      end
    end

    def self.bulk_add_species!(species)
      puts 'Bulk adding...'
      Search.instance.with do |conn|
        conn.index('species').add_or_replace_documents(species.map {|s| to_document(s) })
      end
      puts 'Bulk Added !'
    end

    def self.to_document(species)
      {
        id: species.id,
        type: 'species',
        scientific_name: species.scientific_name,
        common_name: species.common_name,
        author: species.author,
        slug: species.slug,
        year: species.year,
        status: species.status,
        score: species.gbif_score,
        main_species: species.main_species_id.nil?,
        image_url: species.main_image_url,
        genus_id: species.genus_id,
        genus: species.genus_name,
        family: species.family_name,
        family_common_name: species.family_common_name,
        bibliography: species.bibliography,
        rank: species.rank,
        common_names: species.common_names.where(lang: 'en').pluck(:name),
        synonyms: species.synonyms.pluck(:name)
      }
    end

    def self.reset
      Search.instance.with do |conn|
        (begin
           conn.delete_index('species')
         rescue StandardError
           nil
         end)
        reconfigure_settings
        Search::IndexAllWorker.perform_async
      end
    end

    def self.reconfigure_settings
      Search.instance.with do |conn|
        index = conn.get_or_create_index('species', primaryKey: 'id')
        # conn.index('species').update_ranking_rules(
        #   ["typo", "words", "proximity", "desc(score)", "attribute", "wordsPosition", "exactness"]
        # )

        conn.index('species').update_searchable_attributes(%w[
                                                             scientific_name
                                                             common_name
                                                             common_names
                                                             synonyms
                                                             author
                                                             main_species
                                                             genus
                                                             family
                                                             family_common_name
                                                             year
                                                             bibliography
                                                             id
                                                           ])

        conn.index('species').update_displayed_attributes([
                                                            'id',
                                                            'scientific_name',
                                                            'common_name',
                                                            'author',
                                                            'main_species',
                                                            'image_url',
                                                            'genus_id',
                                                            'genus',
                                                            'family',
                                                            'rank',
                                                            'slug',
                                                            # 'common_names',
                                                            'bibliography',
                                                            'family_common_name',
                                                            'synonyms'
                                                          ])
      end
    end
  end
end
