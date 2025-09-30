class RunCheckWorker
  include Sidekiq::Worker

  sidekiq_options queue: :checks, retry: false, backtrace: true

  def perform(species_id)
    ::Checks.run_all(species_id)
  end
end
