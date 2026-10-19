# Empties a flag column still holding the mask of a superseded or rejected
# fact (Migrators::StaleFactProjection), so Migrators::FactPromotionWorker can
# refill it from the current fact. Written for the 2026-10 TRY phenology fix
# (trefle-crawlers#55: dataset 174 read as weeks). Dry run by default.
#
#   Migrators::StaleFactProjectionWorker.new.perform                         # dry run: bloom_months, TRY dataset 174
#   Migrators::StaleFactProjectionWorker.new.perform(false)                  # for real
#   Migrators::StaleFactProjectionWorker.new.perform(true, 'bloom_months', nil)  # every stale TRY mask, any dataset
class Migrators::StaleFactProjectionWorker

  include Sidekiq::Worker
  sidekiq_options queue: :migrations, retry: false, backtrace: true

  # Dataset citations are a TRY notion, so the source is TRY here; the
  # migrator itself takes any source.
  def perform(dry_run = true, attribute = 'bloom_months', dataset = 174) # rubocop:disable Style/OptionalBooleanParameter
    DataRun.track!(runnable: self.class.name, kind: 'migration',
                   arguments: { attribute: attribute, source: 'try', dataset: dataset }, dry_run: dry_run) do
      ActiveRecord::Base.uncached do
        ::Migrators::StaleFactProjection.run(attribute: attribute, source: 'try', dataset: dataset,
                                             dry_run: dry_run).to_h
      end
    end
  end

end
