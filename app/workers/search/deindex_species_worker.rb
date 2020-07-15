module Search
  # Will remove the given species from indexes
  class DeindexSpeciesWorker
    include Sidekiq::Worker

    def perform(species_id)
      ::Search.instance.with do |conn|
        conn.index('species').delete_document(species_id)
      end
    end
  end
end
