# Turns protocol-relative image links into https ones (Migrators::ImageUrlProtocol, #419).
# Dry run by default.
#
#   Migrators::ImageUrlProtocolWorker.new.perform          # dry run
#   Migrators::ImageUrlProtocolWorker.new.perform(false)   # for real
class Migrators::ImageUrlProtocolWorker

  include Sidekiq::Worker
  sidekiq_options queue: :migrations, retry: false, backtrace: true

  def perform(dry_run = true) # rubocop:disable Style/OptionalBooleanParameter
    DataRun.track!(runnable: self.class.name, kind: 'migration', dry_run: dry_run) do
      ActiveRecord::Base.uncached { ::Migrators::ImageUrlProtocol.run(dry_run: dry_run).to_h }
    end
  end

end
