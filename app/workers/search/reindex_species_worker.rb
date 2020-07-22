module Search
  # Will reindex the given species
  class ReindexSpeciesWorker
    include Sidekiq::Worker

    def perform
      Searchkick::ProcessQueueJob.perform_now(class_name: 'Species')
    end
  end
end
