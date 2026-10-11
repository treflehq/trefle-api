# Rewrites ISO 639-2 language codes of common names to 639-1 and drops the duplicates (Migrators::CommonNameLanguages, #419).
# Dry run by default.
#
#   Migrators::CommonNameLanguagesWorker.new.perform          # dry run
#   Migrators::CommonNameLanguagesWorker.new.perform(false)   # for real
class Migrators::CommonNameLanguagesWorker

  include Sidekiq::Worker
  sidekiq_options queue: :migrations, retry: false, backtrace: true

  def perform(dry_run = true) # rubocop:disable Style/OptionalBooleanParameter
    DataRun.track!(runnable: self.class.name, kind: 'migration', dry_run: dry_run) do
      ActiveRecord::Base.uncached { ::Migrators::CommonNameLanguages.run(dry_run: dry_run).to_h }
    end
  end

end
