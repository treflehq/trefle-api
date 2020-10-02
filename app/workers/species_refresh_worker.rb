# Will update the queries counters
class SpeciesRefreshWorker
  include Sidekiq::Worker

  sidekiq_options queue: :low, retry: false, backtrace: true

  def perform(species_id)
    ::Species.find(species_id).save
  end
end
