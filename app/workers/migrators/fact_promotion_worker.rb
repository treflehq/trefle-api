# Promotes sourced facts into the empty trait columns they claim (#328).
# Defaults to a dry run: this job writes the columns the API serves.
#
#   Migrators::FactPromotionWorker.new.perform('try')          # dry run
#   Migrators::FactPromotionWorker.new.perform('try', false)   # for real
#
# Journaled through DataRun like the import that produced the facts, so the
# promotion and its measured impact sit next to it in /management/data_runs.
class Migrators::FactPromotionWorker

  include Sidekiq::Worker
  sidekiq_options queue: :migrations, retry: false, backtrace: true

  def perform(source = nil, dry_run = true, limit = nil) # rubocop:disable Style/OptionalBooleanParameter
    DataRun.track!(runnable: self.class.name, kind: 'migration',
                   arguments: { source: source, limit: limit }, dry_run: dry_run) do
      ::Migrators::FactPromotion.run(source: source, dry_run: dry_run, limit: limit).to_h
    end
  end

end
