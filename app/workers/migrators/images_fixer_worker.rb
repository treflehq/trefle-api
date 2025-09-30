# Will update the counters if needed
class Migrators::ImagesFixerWorker
  include Sidekiq::Worker
  sidekiq_options queue: :migrations, retry: true, backtrace: true

  def perform(species_id = nil)
    if species_id.nil?
      Species.find_each do |sp|
        ::Migrators::ImagesFixerWorker.perform_async(sp.id)
      end
    else
      Migrators::ImagesFixer.run(species_id)
    end
    true
  end
end
