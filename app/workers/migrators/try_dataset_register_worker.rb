# Seeds the TRY dataset register (treflehq/trefle-crawlers#26).
#
#   Migrators::TryDatasetRegisterWorker.new.perform        # dry run
#   Migrators::TryDatasetRegisterWorker.new.perform(false)  # for real
class Migrators::TryDatasetRegisterWorker

  include Sidekiq::Worker
  sidekiq_options queue: :migrations, retry: false, backtrace: true

  def perform(dry_run = true) # rubocop:disable Style/OptionalBooleanParameter
    ::Migrators::TryDatasetRegister.run(dry_run: dry_run)
  end

end
