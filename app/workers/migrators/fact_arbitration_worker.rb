# Lets a strictly stronger source's active fact replace a trait value backed
# only by a weaker one or by nothing (Migrators::FactArbitration). Dry run by
# default. Options (string keys, as Sidekiq passes them): attributes (column
# names; the set columns are only arbitrated when named), limit (species),
# min_observations.
#
#   Migrators::FactArbitrationWorker.new.perform                     # dry run, every trait column
#   Migrators::FactArbitrationWorker.new.perform(false)              # for real
#   Migrators::FactArbitrationWorker.new.perform(false, 'attributes' => %w[light], 'limit' => 10)
class Migrators::FactArbitrationWorker

  include Sidekiq::Worker
  sidekiq_options queue: :migrations, retry: false, backtrace: true

  OPTIONS = %w[attributes limit min_observations].freeze

  def perform(dry_run = true, options = {}) # rubocop:disable Style/OptionalBooleanParameter
    options = options.to_h.stringify_keys.slice(*OPTIONS).compact
    DataRun.track!(runnable: self.class.name, kind: 'migration', arguments: options, dry_run: dry_run) do
      ActiveRecord::Base.uncached do
        ::Migrators::FactArbitration.run(dry_run: dry_run, **options.symbolize_keys).to_h
      end
    end
  end

end
