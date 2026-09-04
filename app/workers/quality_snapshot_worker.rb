# Writes the weekly data-quality snapshot (fill rates, implausible values,
# source conflicts) — see Quality::Snapshot and DataQualitySnapshot.
class QualitySnapshotWorker
  include Sidekiq::Worker

  sidekiq_options queue: :low, retry: false, backtrace: true

  def perform
    result = Quality::Snapshot.run!
    Rails.logger.info("[QualitySnapshotWorker] #{result.inspect}")
  end
end
