module Search
  # Will reindex all plants
  class IndexAllWorker
    include Sidekiq::Worker

    def perform
      ::Species.reindex
    end
  end
end
