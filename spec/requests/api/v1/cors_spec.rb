require 'rails_helper'

RSpec.describe 'CORS on the public API', type: :request do

  let(:user) { create(:user) }
  let(:origin) { 'https://example.com' }

  describe 'preflight' do
    it 'answers an OPTIONS preflight for a GET /api/v1 endpoint with the CORS headers' do
      options '/api/v1/plants', headers: {
        'Origin' => origin,
        'Access-Control-Request-Method' => 'GET'
      }

      expect(response).to have_http_status(:ok)
      expect(response.headers['Access-Control-Allow-Origin']).to eq('*')
      expect(response.headers['Access-Control-Allow-Methods']).to include('GET')
    end

    it 'answers an OPTIONS preflight for POST /api/auth/claim with the CORS headers' do
      options '/api/auth/claim', headers: {
        'Origin' => origin,
        'Access-Control-Request-Method' => 'POST'
      }

      expect(response).to have_http_status(:ok)
      expect(response.headers['Access-Control-Allow-Origin']).to eq('*')
      expect(response.headers['Access-Control-Allow-Methods']).to include('POST')
    end
  end

  describe 'actual requests' do
    it 'carries Access-Control-Allow-Origin on a cross-origin GET to /api/v1' do
      get '/api/v1/plants', headers: { 'Origin' => origin, 'Authorization' => "Bearer #{user.token}" }

      expect(response).to have_http_status(:ok)
      expect(response.headers['Access-Control-Allow-Origin']).to eq('*')
    end

    it 'exposes the RateLimit-* headers to cross-origin clients' do
      get '/api/v1/plants', headers: { 'Origin' => origin, 'Authorization' => "Bearer #{user.token}" }

      expect(response.headers['Access-Control-Expose-Headers']).to include('RateLimit-Limit', 'RateLimit-Remaining', 'RateLimit-Reset')
    end

    it 'does not add CORS headers to non-API routes' do
      get '/', headers: { 'Origin' => origin }

      expect(response.headers['Access-Control-Allow-Origin']).to be_nil
    end

    it 'does not add CORS headers to a cross-origin POST to a write endpoint' do
      plant = create(:plant)

      post "/api/v1/plants/#{plant.id}/report",
           params: { reason: 'test' },
           headers: { 'Origin' => origin, 'Authorization' => "Bearer #{user.token}" }

      expect(response.headers['Access-Control-Allow-Origin']).to be_nil
    end
  end

end
