# Empties a maximum height below the average height of the record (Migrators::HeightConsistency, #419).
# Dry run by default.
#
#   Migrators::HeightConsistencyWorker.new.perform          # dry run
#   Migrators::HeightConsistencyWorker.new.perform(false)   # for real
class Migrators::HeightConsistencyWorker

  include Sidekiq::Worker
  sidekiq_options queue: :migrations, retry: false, backtrace: true

  def perform(dry_run = true) # rubocop:disable Style/OptionalBooleanParameter
    DataRun.track!(runnable: self.class.name, kind: 'migration', dry_run: dry_run) do
      ActiveRecord::Base.uncached { ::Migrators::HeightConsistency.run(dry_run: dry_run).to_h }
    end
  end

end
