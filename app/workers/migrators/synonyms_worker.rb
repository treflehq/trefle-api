class Migrators::SynonymsWorker
  include Sidekiq::Worker
  sidekiq_options queue: :migrations, retry: true, backtrace: true

  def perform(*_args)
    ::Migrators::Synonyms.run
  end
end
