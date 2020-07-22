require_relative 'boot'

# require 'rails'
# Pick the frameworks you want:
require 'active_model/railtie'
require 'active_job/railtie'
require 'active_record/railtie'
require 'active_storage/engine'
require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'action_view/railtie'
# require "action_cable/engine"
# require 'sprockets/railtie'
require 'rails/test_unit/railtie'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module TrefleAdmin
  class Application < Rails::Application

    VERSION = '1.6.0'.freeze

    # Initialize configuration defaults for originally generated Rails version.
    # config.load_defaults 5.2
    config.load_defaults '6.0'

    Raven.configure do |config|
      config.dsn = ENV['SENTRY_DSN']
      config.environments = %w[production]
    end

    config.autoload_paths << "#{config.root}/lib"
    config.eager_load_paths << "#{config.root}/lib"

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
    # config.middleware.insert_before 0, Rack::Cors do
    #   allow do
    #     origins 'https://trefle.io', %r{\Ahttps://.*\.trefle.io\z}
    #     resource '*',
    #              headers: :any,
    #              methods: :any,
    #              expose: %w[Authorization Link],
    #              max_age: 600
    #   end
    #   allow do
    #     origins %r{\Ahttp://localhost:(3000|3232)}
    #     resource '*',
    #              headers: :any,
    #              methods: :any,
    #              expose: %w[Authorization Link],
    #              max_age: 600
    #   end

    #   allow do
    #     origins '*'

    #     # Preflight
    #     resource '/api/v1/*',
    #         headers: :any,
    #         methods: :options
    #   end

    # end
    config.active_job.queue_adapter = :sidekiq

    config.action_controller.forgery_protection_origin_check = false

  end
end
