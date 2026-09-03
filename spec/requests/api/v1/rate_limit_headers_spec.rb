require 'rails_helper'

RSpec.describe 'Rate limit headers', type: :request do

  # Rack::Attack's Redis-backed counters survive across examples (they're
  # not part of the DB transaction rollback), so every example needs a
  # clean slate to get predictable Remaining/Reset values.
  before { Rack::Attack.cache.reset! }
  after { Rack::Attack.cache.reset! }

  it 'carries RateLimit-* headers on a normal /api/v1 response' do
    get '/api/v1/'

    expect(response).to have_http_status(:ok)
    expect(response.headers['RateLimit-Limit']).to eq('60')
    expect(response.headers['RateLimit-Remaining']).to eq('59')
    expect(response.headers['RateLimit-Reset'].to_i).to be > Time.now.to_i
  end

  it 'decrements RateLimit-Remaining as requests come in' do
    get '/api/v1/'
    get '/api/v1/'

    expect(response.headers['RateLimit-Remaining']).to eq('58')
  end

  it 'carries RateLimit-* headers on the 429 once the limit is exceeded' do
    60.times { get '/api/v1/' }
    get '/api/v1/'

    expect(response).to have_http_status(:too_many_requests)
    expect(response.headers['RateLimit-Limit']).to eq('60')
    expect(response.headers['RateLimit-Remaining']).to eq('0')
    expect(response.headers['RateLimit-Reset'].to_i).to be > Time.now.to_i
  end

end
