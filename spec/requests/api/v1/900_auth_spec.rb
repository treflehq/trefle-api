require 'swagger_helper'

describe 'Auth API' do

  after do |example|
    JsonApiHelper.save_example(example, response)
  end

  claim_schema = Schemas::Helpers.object_of({
    origin: { type: :string, example: 'https://example.com', description: 'The website url the API requests will come from' },
    ip: { type: :string, nullable: true, example: '12.23.34.45', description: 'The client IP' }
  }, extras: { required: %w[origin] })

  let(:user) { create(:user) }
  let(:headers) { { 'CONTENT_TYPE' => 'application/json', 'HTTP_ACCEPT' => 'application/json' } }

  # This endpoint lives at /api/auth/claim, outside the /api/v1 server the
  # rest of the document is relative to, so the path item carries its own
  # `servers`. rswag's run_test! only knows the document server and would call
  # /api/v1/auth/claim: the examples below send the request themselves and
  # still check the response against the declared schema.
  path '/auth/claim' do
    metadata[:path_item][:servers] = [{ url: 'https://trefle.io/api' }]

    post 'Request a client-side token' do
      tags 'Auth'
      consumes 'application/json'
      produces 'application/json'
      description <<~DESC
        If you need to perform client-side requests, you will have to request a client-side token from you backend, and get a JWT token from this API call in return. This token will be usable on the client side. This call need your secret access token, the url of the website the client side requests will come from and optionally the client IP address.
      DESC

      operationId 'claimClientSideToken'
      security [{ token: [] }, { bearerAuth: [] }]
      parameter name: :claim_params, required: true, in: :body, schema: claim_schema

      response '200', 'Success' do
        schema Schemas::Helpers.object_of({
          expiration: { type: :string, example: '07-13-2020 13:41', description: 'The expiration time of the token. After this time, you\'ll have to request a token again' },
          token: { type: :string,
                   example: 'eyJhbGciOiJIUzI1NaJ9.eyJ1c2VyX2lkIjoxMDYsIe9yaWdpbiI6Imh0dHA6Ly9wb2NhbGhvc3Q6MzIzMyIsImlwIjoiOjoxIiwiZXhwIjoxNTk0NjQwNTEzfQ.TyqKyKxwsnn7TZsLAfS8OTmTUPk87CSXlk6a2wQU9co', description: 'The client-side access token, that you\'ll use instead of your access token in the `token` parameter' }
        })

        it 'returns a 200 response' do |example|
          post "/api/auth/claim?token=#{user.token}", params: { origin: 'http://localhost:1234', ip: '::1' }.to_json, headers: headers
          assert_response_matches_metadata(example.metadata)
        end
      end

      response '401', 'Invalid credentials' do
        schema Schemas::Helpers.error_schema

        it 'returns a 401 response' do |example|
          post '/api/auth/claim?token=invalid', params: { ip: '::1' }.to_json, headers: headers
          assert_response_matches_metadata(example.metadata)
        end
      end

      response '422', 'Missing parameters' do
        schema Schemas::Helpers.error_schema

        it 'returns a 422 response' do |example|
          post "/api/auth/claim?token=#{user.token}", params: { ip: '::1' }.to_json, headers: headers
          assert_response_matches_metadata(example.metadata)
        end
      end

      response '429', 'Too many requests: the rate limit is exceeded' do
        schema Schemas::Helpers.error_schema
        header 'RateLimit-Limit', schema: { type: :integer }, description: 'Requests allowed per minute'
        header 'RateLimit-Remaining', schema: { type: :integer }, description: 'Requests left in the current minute'
        header 'RateLimit-Reset', schema: { type: :integer }, description: 'Unix timestamp at which the counter resets'
        header 'Retry-After', schema: { type: :integer }, description: 'Seconds to wait before retrying'

        it 'returns a 429 response' do |example|
          freeze_time do
            60.times { Rack::Attack.cache.count("#{Rack::Attack::REQUEST_PER_IP_THROTTLE}:127.0.0.1-#{user.token.downcase}", 60) }
            post "/api/auth/claim?token=#{user.token}", params: { origin: 'http://localhost:1234' }.to_json, headers: headers
          end
          Rack::Attack.cache.reset!
          assert_response_matches_metadata(example.metadata)
        end
      end
    end
  end

end
