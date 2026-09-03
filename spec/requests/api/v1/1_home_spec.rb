require 'rails_helper'

RSpec.describe 'API home and profile', type: :request do

  describe 'GET /api/v1/' do
    it 'returns the public counters' do
      get '/api/v1/'
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body['plants_count']).to eq(Plant.count)
      expect(body).to have_key('detailled_plants_count')
    end
  end

  describe 'GET /api/v1/me' do
    let(:user) { create(:user) }

    it 'returns the token owner profile' do
      get '/api/v1/me', headers: { 'Authorization' => "Bearer #{user.token}" }
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body['name']).to eq(user.name)
      expect(body['email']).to eq(user.email)
    end

    it 'rejects a missing token' do
      get '/api/v1/me'
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'CORS preflight' do
    it 'answers OPTIONS requests' do
      process :options, '/api/v1/species'
      expect(response.status).to be_between(200, 204)
    end
  end
end
