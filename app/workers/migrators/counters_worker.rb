# Will update the counters if needed
class Migrators::CountersWorker
  include Sidekiq::Worker
  sidekiq_options queue: :migrations, retry: true, backtrace: true

  def perform(*_args)
    SpeciesDistribution.counter_culture_fix_counts
    Species.counter_culture_fix_counts
    ForeignSourcesPlant.counter_culture_fix_counts
    Synonym.counter_culture_fix_counts
    SpeciesImage.counter_culture_fix_counts
    true
  end
end
