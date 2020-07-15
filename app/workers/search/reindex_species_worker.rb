module Search
  # Will reindex the given species
  class ReindexSpeciesWorker
    include Sidekiq::Worker

    def perform(species_id)
      species = Species.find(species_id)
      ::Search::Index.add_species!(species)
    end
  end
end
