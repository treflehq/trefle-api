# Fills each species image's licence, author, commercial-use flag and
# thumbnail from its copyright and URL (Migrators::ImageLicences).
# Dry run by default.
#
#   Migrators::ImageLicencesWorker.new.perform          # dry run
#   Migrators::ImageLicencesWorker.new.perform(false)   # for real
class Migrators::ImageLicencesWorker

  include Sidekiq::Worker
  sidekiq_options queue: :migrations, retry: false, backtrace: true

  def perform(dry_run = true) # rubocop:disable Style/OptionalBooleanParameter
    DataRun.track!(runnable: self.class.name, kind: 'migration', dry_run: dry_run) do
      ActiveRecord::Base.uncached { ::Migrators::ImageLicences.run(dry_run: dry_run).to_h }
    end
  end

end
