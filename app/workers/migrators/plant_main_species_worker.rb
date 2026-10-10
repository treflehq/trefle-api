# Links plants to their root species (#404). Dry run by default.
#
#   Migrators::PlantMainSpeciesWorker.new.perform          # dry run
#   Migrators::PlantMainSpeciesWorker.new.perform(false)   # for real
class Migrators::PlantMainSpeciesWorker

  include Sidekiq::Worker
  sidekiq_options queue: :migrations, retry: false, backtrace: true

  def perform(dry_run = true, limit = nil) # rubocop:disable Style/OptionalBooleanParameter
    DataRun.track!(runnable: self.class.name, kind: 'migration', arguments: { limit: limit }, dry_run: dry_run) do
      ActiveRecord::Base.uncached { ::Migrators::PlantMainSpecies.run(dry_run: dry_run, limit: limit).to_h }
    end
  end

end
