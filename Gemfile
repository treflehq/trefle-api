source 'https://rubygems.org'
git_source(:github) {|repo| "https://github.com/#{repo}.git" }

# ruby '2.4.1'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
# gem 'jquery-rails'
gem 'rails', '>= 6.0.3.2'

gem 'webpacker', '>= 5.x'

# Use postgresql as the database for Active Record
gem 'pg', '>= 0.18', '< 2.0'
# Use Puma as the app server
gem 'puma'
# Use SCSS for stylesheets
# gem 'sass-rails', '>= 5.0'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
# gem 'jbuilder', '>= 2.5'
# Use ActiveModel has_secure_password
gem 'bcrypt', '>= 3.1.7'
gem 'friendly_id', '>= 5.2.4'
# Use ActiveStorage variant
# gem 'mini_magick', '>= 4.8'
gem 'oj'
# gem 'rack-cors', require: 'rack/cors'

# API
# gem 'api-pagination'
# gem 'fast_jsonapi'
gem 'has_scope'
gem 'panko_serializer'

# Caching
gem 'connection_pool'
gem 'dalli'

# Client side tokens
gem 'jwt'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.1.0', require: false
gem 'httparty', require: false
gem 'kaminari'
gem 'pagy', '~> 3.5' # omit patch digit and use the latest if possible
gem 'typhoeus'

# Gravatar
gem 'gravtastic'

gem 'measured'
gem 'measured-rails'

gem 'health_check'

gem 'activerecord-like'
gem 'auto_strip_attributes', '~> 2.5'
gem 'colorize'

gem 'countries', require: false
gem 'devise'
gem 'groupdate'

gem 'active_flag'

# Monitoring
gem 'appsignal'
gem 'pghero'
gem 'pg_query', '>= 0.9.0'
gem 'rack-attack', '~> 6.2.2'
gem 'sentry-raven'
gem 'skylight'

# Sidekiq
gem 'redis', '~> 4.1.4'
gem 'redis-namespace', '~> 1.7.0'
gem 'rufus-scheduler', '~> 3.4.2'
gem 'sidekiq', '~> 6.0.7'
gem 'sidekiq-cron', '~> 0.6.3'
gem 'sidekiq-limit_fetch'
gem 'sidekiq-status'

gem 'counter_culture', '~> 2.0'
gem 'interactor-rails', '~> 2.2.1'

gem 'nokogiri'
gem 'terminal-table'

gem 'json-schema'

# gem 'meilisearch'
gem 'searchkick'

# SEO
gem 'meta-tags'
gem 'sitemap_generator'

# profiling
gem 'derailed_benchmarks'
gem 'memory_profiler'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: %i[mri mingw x64_mingw]
  gem 'coveralls', '>= 0.8.23', require: false
  gem 'database_cleaner', '>= 1.8.5'
  gem 'dotenv-rails', '>= 2.7.5'
  gem 'marginalia', '>= 1.8.0' # annotate queries
  gem 'pry'
  gem 'rails-controller-testing'
  gem 'rspec'
  gem 'rspec-rails'
  gem 'rswag', github: 'pedrocarmona/rswag'
  # gem 'rswag'
  gem 'factory_bot', '~> 5.1.2'
  gem 'faker', '~> 2.1.2'
  gem 'seed_dump'
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'web-console', '>= 3.3.0'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '>= 2.0.0'
  # Add annotations on models
  gem 'annotate'

end

group :test do
  # Adds support for Capybara system testing and selenium driver
  gem 'capybara', '>= 2.15'
  gem 'selenium-webdriver'
  # Easy installation and use of chromedriver to run system tests with Chrome
  gem 'chromedriver-helper'

  gem 'simplecov', '>= 0.16.1', require: false
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]
