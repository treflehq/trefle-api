class Migrators::SynonymsDuplicateWorker
  include Sidekiq::Worker
  sidekiq_options queue: :migrations, retry: true, backtrace: true

  def perform(*_args)
    ::Migrators::SynonymsDuplicate.run
  end
end
