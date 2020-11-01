class Migrators::SpeciesScientificNamesSubspeciesWorker
  include Sidekiq::Worker
  sidekiq_options queue: :migrations, retry: true, backtrace: true

  def perform(*_args)
    ::Migrators::SpeciesScientificNamesSubspecies.run
  end
end
