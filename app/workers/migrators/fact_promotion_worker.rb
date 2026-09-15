# Promotes sourced facts into the empty trait columns they claim (#328).
# Defaults to a dry run: this job writes the columns the API serves.
#
#   Migrators::FactPromotionWorker.new.perform('try')          # dry run
#   Migrators::FactPromotionWorker.new.perform('try', false)   # for real
class Migrators::FactPromotionWorker

  include Sidekiq::Worker
  sidekiq_options queue: :migrations, retry: false, backtrace: true

  def perform(source = nil, dry_run = true, limit = nil) # rubocop:disable Style/OptionalBooleanParameter
    ::Migrators::FactPromotion.run(source: source, dry_run: dry_run, limit: limit)
  end

end
