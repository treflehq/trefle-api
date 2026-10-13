# Tags the 2022 USDA English common names that have no language with en (Migrators::CommonNameMissingLanguage).
# Dry run by default.
#
#   Migrators::CommonNameMissingLanguageWorker.new.perform          # dry run
#   Migrators::CommonNameMissingLanguageWorker.new.perform(false)   # for real
class Migrators::CommonNameMissingLanguageWorker

  include Sidekiq::Worker
  sidekiq_options queue: :migrations, retry: false, backtrace: true

  def perform(dry_run = true) # rubocop:disable Style/OptionalBooleanParameter
    DataRun.track!(runnable: self.class.name, kind: 'migration', dry_run: dry_run) do
      ActiveRecord::Base.uncached { ::Migrators::CommonNameMissingLanguage.run(dry_run: dry_run).to_h }
    end
  end

end
