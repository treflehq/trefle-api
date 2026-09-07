class Migrators::SourceLicencesWorker
  include Sidekiq::Worker
  sidekiq_options queue: :migrations, retry: true, backtrace: true

  def perform(*_args)
    ::Migrators::SourceLicences.run
  end
end
