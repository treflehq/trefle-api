class Migrators::UpdateCorrectionSpeciesReferencesWorker
  include Sidekiq::Worker
  sidekiq_options queue: :migrations, retry: true, backtrace: true

  def perform(*_args)
    ::Migrators::UpdateCorrectionSpeciesReferences.run
  end
end
