class Migrators::UsdaReferencesWorker
  include Sidekiq::Worker
  sidekiq_options queue: :migrations, retry: true, backtrace: true

  def perform(*_args)
    ::Migrators::UsdaReferences.run
  end
end
