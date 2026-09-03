# Feeds the data-quality checks continuously: every run picks the
# species that have waited the longest (never checked first) and
# enqueues a RunCheckWorker for each.
class ChecksSweepWorker
  include Sidekiq::Worker

  sidekiq_options queue: :checks, retry: false, backtrace: true

  DEFAULT_BATCH_SIZE = 200

  def perform(batch_size = DEFAULT_BATCH_SIZE)
    Species
      .order(Arel.sql('checked_at ASC NULLS FIRST'))
      .limit(batch_size)
      .pluck(:id)
      .each {|id| RunCheckWorker.perform_async(id) }
  end
end
