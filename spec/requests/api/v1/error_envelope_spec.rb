require 'rails_helper'

# Covers the documented error envelope from issue #216: one shape --
# `{ error: true, code:, message:, messages:, details: }` -- across every
# kind of /api error (400/401/404/422/429), plus the malformed-JSON case
# that used to leak an HTML error page instead of JSON (#126).
RSpec.describe 'API error envelope', type: :request do
  let(:user) { create(:user) }

  describe 'GET /api/v1/species with an unknown filter key' do
    before { get '/api/v1/species', params: { token: user.token, filter: { not_a_real_field: 'x' } } }

    it_behaves_like 'renders API errors', status: :bad_request, code: 'bad_request'
  end

  describe 'GET /api/v1/plants without a token' do
    before { get '/api/v1/plants' }

    it_behaves_like 'renders API errors', status: :unauthorized, code: 'unauthorized'
  end

  describe 'GET /api/v1/plants/:id for an unknown slug' do
    before { get '/api/v1/plants/does-not-exist-at-all', params: { token: user.token } }

    it_behaves_like 'renders API errors', status: :not_found, code: 'not_found'
  end

  describe 'POST /api/auth/claim missing a required param' do
    before { post '/api/auth/claim', params: { token: user.token } }

    it_behaves_like 'renders API errors', status: :unprocessable_entity, code: 'unprocessable_entity'
  end

  describe 'exceeding the rate limit' do
    before do
      Rack::Attack.cache.reset!
      60.times { get '/api/v1/', params: { token: user.token } }
      get '/api/v1/', params: { token: user.token }
    end

    after { Rack::Attack.cache.reset! }

    it_behaves_like 'renders API errors', status: :too_many_requests, code: 'too_many_requests'
  end

  describe 'a malformed JSON body' do
    before do
      post '/api/auth/claim', params: '{"broken json', headers: { 'CONTENT_TYPE' => 'application/json' }
    end

    it_behaves_like 'renders API errors', status: :bad_request, code: 'bad_request'

    it 'never falls back to an HTML error page' do
      expect(response.content_type).to match(%r{application/json})
      expect(response.body).not_to include('<html')
    end
  end

  describe 'an unexpected server error' do
    before do
      allow(Species).to receive(:friendly).and_raise(RuntimeError, 'boom')
      get '/api/v1/plants/abies-alba', params: { token: user.token }
    end

    it_behaves_like 'renders API errors', status: :internal_server_error, code: 'internal_server_error'

    it 'never falls back to an HTML error page' do
      expect(response.content_type).to match(%r{application/json})
      expect(response.body).not_to include('<html')
    end
  end
end
