class Migrators::SynonymsDuplicatesWorker
  include Sidekiq::Worker
  sidekiq_options queue: :migrations, retry: true, backtrace: true

  def perform(*_args)
    ::Migrators::SynonymsDuplicates.run
  end
end
