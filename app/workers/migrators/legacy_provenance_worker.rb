# Gives every trait value served from a species column without an active fact a legacy fact (Migrators::LegacyProvenance).
# Dry run by default.
#
#   Migrators::LegacyProvenanceWorker.new.perform          # dry run
#   Migrators::LegacyProvenanceWorker.new.perform(false)   # for real
class Migrators::LegacyProvenanceWorker

  include Sidekiq::Worker
  sidekiq_options queue: :migrations, retry: false, backtrace: true

  def perform(dry_run = true) # rubocop:disable Style/OptionalBooleanParameter
    DataRun.track!(runnable: self.class.name, kind: 'migration', dry_run: dry_run) do
      ActiveRecord::Base.uncached { ::Migrators::LegacyProvenance.run(dry_run: dry_run).to_h }
    end
  end

end
