require 'rails_helper'

RSpec.describe 'Sentry configuration' do
  it 'only enables reporting for the production environment' do
    expect(Sentry.configuration.enabled_environments).to eq(%w[production])
  end

  it 'refuses to report from a development checkout even with a DSN configured' do
    config = Sentry::Configuration.new
    config.enabled_environments = %w[production]
    config.environment = 'development'

    expect(config.enabled_in_current_env?).to eq(false)
  end

  it 'reports from the production environment (also used by the trefle-api-next deployment)' do
    config = Sentry::Configuration.new
    config.enabled_environments = %w[production]
    config.environment = 'production'

    expect(config.enabled_in_current_env?).to eq(true)
  end
end
