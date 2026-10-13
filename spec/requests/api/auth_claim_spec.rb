require 'rails_helper'

# POST /api/auth/claim: the account token is read like on every other
# endpoint (the `token` parameter, or `Authorization: Bearer`), the response
# carries an ISO 8601 `expires_at`, and the JWTs claimed by an account share
# that account's rate-limit bucket.
RSpec.describe 'POST /api/auth/claim', type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create(:user) }
  let(:json_headers) { { 'CONTENT_TYPE' => 'application/json', 'HTTP_ACCEPT' => 'application/json' } }
  let(:body) { { origin: 'https://example.com' }.to_json }

  before { Rack::Attack.cache.reset! }
  after { Rack::Attack.cache.reset! }

  def claim(headers: {}, query: nil, payload: body)
    post ['/api/auth/claim', query].compact.join('?'), params: payload, headers: json_headers.merge(headers)
  end

  def claim_jwt(origin: 'https://example.com')
    claim(headers: { 'Authorization' => "Bearer #{user.token}" }, payload: { origin: origin }.to_json)
    response.parsed_body['token']
  end

  describe 'where the account token comes from' do
    it 'accepts it as a Bearer token, the scheme the OpenAPI document announces' do
      claim(headers: { 'Authorization' => "Bearer #{user.token}" })

      expect(response).to have_http_status(:ok)
      expect(Auth::JsonWebToken.decode(response.parsed_body['token'])).to include('user_id' => user.id, 'origin' => 'https://example.com')
    end

    it 'still accepts it as a query parameter' do
      claim(query: "token=#{user.token}")

      expect(response).to have_http_status(:ok)
    end

    it 'still accepts it in the JSON body' do
      claim(payload: { token: user.token, origin: 'https://example.com' }.to_json)

      expect(response).to have_http_status(:ok)
    end

    it 'answers 401 without a token' do
      claim

      expect(response).to have_http_status(:unauthorized)
    end

    it 'answers 401 to an unknown token' do
      claim(headers: { 'Authorization' => 'Bearer not-a-token' })

      expect(response).to have_http_status(:unauthorized)
    end

    it 'does not let a JWT claim another one' do
      jwt = claim_jwt

      claim(headers: { 'Authorization' => "Bearer #{jwt}", 'Origin' => 'https://example.com' })

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body['message']).to eq('Invalid credentials')
    end

    it 'answers 422 naming origin when origin is missing' do
      claim(headers: { 'Authorization' => "Bearer #{user.token}" }, payload: { ip: '::1' }.to_json)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body['message']).to include('origin')
    end
  end

  describe 'the expiration' do
    it 'is given in ISO 8601 UTC as expires_at, 24 hours ahead, next to the legacy expiration' do
      freeze_time do
        claim(headers: { 'Authorization' => "Bearer #{user.token}" })

        expires_at = response.parsed_body['expires_at']
        expect(expires_at).to match(/\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z\z/)
        expect(Time.iso8601(expires_at)).to eq(24.hours.from_now.change(usec: 0))
        expect(response.parsed_body['expiration']).to eq(24.hours.from_now.strftime('%m-%d-%Y %H:%M'))
      end
    end
  end

  describe 'rate limiting' do
    def bucket_count(token)
      Rack::Attack.cache.store.read("#{Rack::Attack.cache.prefix}:#{Time.now.to_i / 60}:#{Rack::Attack::REQUEST_PER_IP_THROTTLE}:127.0.0.1-#{token.downcase}").to_i
    end

    it 'counts the requests made with a claimed JWT against the account token' do
      first_jwt = claim_jwt
      second_jwt = claim_jwt(origin: 'https://other.example.com')
      expect(first_jwt).not_to eq(second_jwt)

      get '/api/v1/kingdoms', headers: { 'Authorization' => "Bearer #{first_jwt}" }
      get '/api/v1/kingdoms', headers: { 'Authorization' => "Bearer #{second_jwt}" }
      get '/api/v1/kingdoms', params: { token: second_jwt }

      # Two claims and three reads, all in the account's bucket.
      expect(bucket_count(user.token)).to eq(5)
      expect(bucket_count(first_jwt)).to eq(0)
    end

    it 'throttles a JWT once its account has used up the quota' do
      jwt = claim_jwt
      freeze_time do
        60.times { Rack::Attack.cache.count("#{Rack::Attack::REQUEST_PER_IP_THROTTLE}:127.0.0.1-#{user.token.downcase}", 60) }

        get '/api/v1/kingdoms', headers: { 'Authorization' => "Bearer #{jwt}" }
      end

      expect(response).to have_http_status(:too_many_requests)
    end

    it 'keeps its own key for a JWT that does not decode' do
      forged = "#{'x' * 60}.#{'y' * 20}.z"

      get '/api/v1/kingdoms', headers: { 'Authorization' => "Bearer #{forged}" }

      expect(response).to have_http_status(:unauthorized)
      expect(bucket_count(forged)).to eq(1)
    end

    it 'gives the JWT of a sponsor account the sponsor limit' do
      user.update_columns(token: "spo-#{SecureRandom.hex(8)}")
      jwt = claim_jwt

      get '/api/v1/kingdoms', headers: { 'Authorization' => "Bearer #{jwt}" }

      expect(response.headers['RateLimit-Limit']).to eq('600')
    end

    it 'does not extend the exemption of an unlimited account to its JWTs' do
      user.update_columns(token: "unl-#{SecureRandom.hex(8)}")
      jwt = claim_jwt

      get '/api/v1/kingdoms', headers: { 'Authorization' => "Bearer #{jwt}" }

      expect(response.headers['RateLimit-Limit']).to eq('60')
    end
  end
end
