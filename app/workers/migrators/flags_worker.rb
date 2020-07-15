class Migrators::FlagsWorker
  include Sidekiq::Worker
  sidekiq_options queue: :migrations, retry: true, backtrace: true

  def perform(*_args)
    ::Migrators::Flags.run
  end
end
