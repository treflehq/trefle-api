module Search
  # Will reindex all plants
  class IndexAllWorker
    include Sidekiq::Worker

    SIZE = 1000

    def perform(start = 0, max = nil)
      max ||= Species.maximum(:id)
      puts "Indexing species from #{start} to #{start + SIZE} (over #{max})"
      Species.find_in_batches(start: start, finish: start + SIZE + 1) do |species|
        puts "Ready to index #{species.count} species"
        ::Search::Index.bulk_add_species!(species)
        puts "At the end: #{species.count} species indexed"
        count = species.count
      end

      return if max <= start + SIZE

      puts "Scheduling index -> #{start + SIZE}"
      IndexAllWorker.perform_async(start + SIZE, max)
    end
  end
end
