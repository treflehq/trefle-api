Rails.application.configure do # rubocop:todo Metrics/BlockLength
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enable/disable caching. By default caching is disabled.
  # Run rails dev:cache to toggle caching.
  if Rails.root.join('tmp', 'caching-dev.txt').exist?
    config.action_controller.perform_caching = true
    config.action_controller.enable_fragment_cache_logging = true

    # config.cache_store = :memory_store
    config.cache_store = :dalli_store

    config.public_file_server.headers = {
      'Cache-Control' => "public, max-age=#{2.days.to_i}"
    }
    # config.cache_store

  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end

  # Store uploaded files on the local file system (see config/storage.yml for options)
  config.active_storage.service = :local

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  config.action_mailer.perform_caching = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  # config.assets.debug = true

  # Suppress logger output for asset requests.
  # config.assets.quiet = true

  config.action_mailer.default_url_options = { host: 'localhost', port: ENV['PORT'] || 3000 }
  config.default_url_options = config.action_mailer.default_url_options
  Rails.application.default_url_options = config.action_mailer.default_url_options

  if ENV['LOCAL_MAILER'] == 'true'
    puts '📩  Warning: Mailer is activated, mails will be sent for real'

    config.action_mailer.delivery_method = :smtp
    config.action_mailer.perform_deliveries = true

    mail_metadatas = {
      address: ENV['SMTP_ADDRESS'] || Rails.application.credentials.smtp_address,
      port: ENV['SMTP_PORT'] || Rails.application.credentials.smtp_port,
      user_name: ENV['SMTP_USER_NAME'] || Rails.application.credentials.smtp_user_name,
      password: ENV['SMTP_PASSWORD'] || Rails.application.credentials.smtp_password,
      domain: ENV['SMTP_DOMAIN'] || Rails.application.credentials.smtp_domain,
      authentication: ENV['SMTP_AUTHENTICATION'] || Rails.application.credentials.smtp_authentication || 'login',
      enable_starttls_auto: ENV['SMTP_ENABLE_STARTTLS_AUTO'] || Rails.application.credentials.smtp_enable_starttls_auto || true
    }

    config.action_mailer.smtp_settings = mail_metadatas
  end

  config.hosts << '261ea83ecfa4.eu.ngrok.io'

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  # Use an evented file watcher to asynchronously detect changes in source code,
  # routes, locales, etc. This feature depends on the listen gem.
  config.file_watcher = ActiveSupport::EventedFileUpdateChecker

  #   allow do
  #      origins '*'
  #      resource '*', :headers => :any, :methods => [:get, :post, :options]
  #    end
  # end
  # config.middleware.insert_before 0, Rack::Cors do
  #   allow do
  #     origins %r{\Ahttp://localhost:(3000|3232)}
  #     resource '*',
  #              headers: :any,
  #              methods: :any,
  #              expose: %w[Authorization Link],
  #              max_age: 600
  #   end
  # end

  config.action_controller.forgery_protection_origin_check = false

end
