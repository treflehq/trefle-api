module Search
  # Will reindex the given species
  class ReindexSpeciesWorker
    include Sidekiq::Worker

    def perform(species_id)
      species = Species.find(species_id)
      ::Search::Index.add_species!(species)
    rescue ActiveRecord::RecordNotFound
      ::Search.instance.with do |conn|
        conn.index('species').delete_document(species_id)
      end
    end
  end
end
