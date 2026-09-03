class RunCheckWorker
  include Sidekiq::Worker

  sidekiq_options queue: :checks, retry: false, backtrace: true

  def perform(species_id)
    ::Checks.run_all(species_id)
    # Timestamp without callbacks so ChecksSweepWorker can rotate
    # through the whole table oldest-first.
    Species.where(id: species_id).update_all(checked_at: Time.zone.now) # rubocop:disable Rails/SkipsModelValidations
  end
end
