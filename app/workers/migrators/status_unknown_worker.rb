# Sets the status of species with a NULL status to unknown (Migrators::StatusUnknown).
# Dry run by default.
#
#   Migrators::StatusUnknownWorker.new.perform          # dry run
#   Migrators::StatusUnknownWorker.new.perform(false)   # for real
class Migrators::StatusUnknownWorker

  include Sidekiq::Worker
  sidekiq_options queue: :migrations, retry: false, backtrace: true

  def perform(dry_run = true) # rubocop:disable Style/OptionalBooleanParameter
    DataRun.track!(runnable: self.class.name, kind: 'migration', dry_run: dry_run) do
      ActiveRecord::Base.uncached { ::Migrators::StatusUnknown.run(dry_run: dry_run).to_h }
    end
  end

end
