# Will update the counters if needed
class Migrators::MainImagesWorker
  include Sidekiq::Worker
  sidekiq_options queue: :migrations, retry: true, backtrace: true

  def perform(*_args)
    Migrators::MainImages.run
    true
  end
end
