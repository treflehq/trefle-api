require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded any time
  # it changes. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enable server timing
  config.server_timing = true

  # Enable/disable caching. By default caching is disabled.
  # Run rails dev:cache to toggle caching.
  if Rails.root.join("tmp/caching-dev.txt").exist?
    config.action_controller.perform_caching = true
    config.action_controller.enable_fragment_cache_logging = true

    config.cache_store = :mem_cache_store
    config.public_file_server.headers = {
      "Cache-Control" => "public, max-age=#{2.days.to_i}"
    }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  config.action_mailer.perform_caching = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise exceptions for disallowed deprecations.
  config.active_support.disallowed_deprecation = :raise

  # Tell Active Support which deprecation messages to disallow.
  config.active_support.disallowed_deprecation_warnings = []

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true

  # Suppress logger output for asset requests.
  config.assets.quiet = false
  config.assets.debug = true

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

  # Raises error for missing translations.
  # config.i18n.raise_on_missing_translations = true

  # Annotate rendered view with file names.
  # config.action_view.annotate_rendered_view_with_filenames = true

  # Uncomment if you wish to allow Action Cable access from any origin.
  # config.action_cable.disable_request_forgery_protection = true
end
