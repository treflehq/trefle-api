# Removes duplicate (species, zone) distribution rows (Migrators::DistributionDuplicates, #419).
# Dry run by default.
#
#   Migrators::DistributionDuplicatesWorker.new.perform          # dry run
#   Migrators::DistributionDuplicatesWorker.new.perform(false)   # for real
class Migrators::DistributionDuplicatesWorker

  include Sidekiq::Worker
  sidekiq_options queue: :migrations, retry: false, backtrace: true

  def perform(dry_run = true) # rubocop:disable Style/OptionalBooleanParameter
    DataRun.track!(runnable: self.class.name, kind: 'migration', dry_run: dry_run) do
      ActiveRecord::Base.uncached { ::Migrators::DistributionDuplicates.run(dry_run: dry_run).to_h }
    end
  end

end
