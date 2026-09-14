Sentry.init do |config|
  # Only the deployed image should ever report. The Dockerfile hardcodes
  # RAILS_ENV=production for every build, so this also covers the
  # trefle-api-next (staging) deployment, and keeps a developer's laptop
  # (RAILS_ENV=development, e.g. `rails runner`) from reporting into the
  # same Sentry project as production traffic just because SENTRY_DSN
  # happens to be set locally.
  config.enabled_environments = %w[production]

  config.dsn = ENV['SENTRY_DSN']
  config.breadcrumbs_logger = %i[active_support_logger http_logger]

  # Set traces_sample_rate to 1.0 to capture 100%
  # of transactions for performance monitoring.
  # We recommend adjusting this value in production.
  config.traces_sample_rate = 0.01
end
