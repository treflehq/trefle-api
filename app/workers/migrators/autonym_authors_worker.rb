# Blanks the authorship of autonyms, leaving rejected facts as the trace (Migrators::AutonymAuthors).
# Dry run by default.
#
#   Migrators::AutonymAuthorsWorker.new.perform          # dry run
#   Migrators::AutonymAuthorsWorker.new.perform(false)   # for real
class Migrators::AutonymAuthorsWorker

  include Sidekiq::Worker
  sidekiq_options queue: :migrations, retry: false, backtrace: true

  def perform(dry_run = true) # rubocop:disable Style/OptionalBooleanParameter
    DataRun.track!(runnable: self.class.name, kind: 'migration', dry_run: dry_run) do
      ActiveRecord::Base.uncached { ::Migrators::AutonymAuthors.run(dry_run: dry_run).to_h }
    end
  end

end
