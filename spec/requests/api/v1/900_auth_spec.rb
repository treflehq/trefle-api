require 'swagger_helper'

describe 'Auth API' do

  after do |example|
    JsonApiHelper.save_example(example, response)
  end

  claim_schema = Schemas::Helpers.object_of({
    origin: { type: :string, example: 'https://example.com',
              description: 'The origin (scheme, host and port) of the website the client-side requests will come from, as browsers send it in the `Origin` header. A request whose `Origin` header differs is refused.' },
    ip: { type: :string, nullable: true, example: '12.23.34.45', description: 'Optional: the IP address of the end user. When given, the token only works from that address.' }
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
        If you need to perform client-side requests, request a client-side token from your backend and get a JWT in return. That token is usable on the client side, in place of your account token, for 24 hours.

        This call needs your secret account token, as `Authorization: Bearer <token>` or as the `token` query parameter, the origin of the website the client-side requests will come from, and optionally the end user's IP address. A client-side token cannot claim another one.

        Requests made with a client-side token count against the rate limit of the account that claimed it.
      DESC

      operationId 'claimClientSideToken'
      security [{ token: [] }, { bearerAuth: [] }]
      parameter name: :claim_params, required: true, in: :body, schema: claim_schema

      response '200', 'Success' do
        schema Schemas::Helpers.object_of({
          expires_at: { type: :string, format: 'date-time', example: '2020-07-13T13:41:00Z', description: 'When the token expires, in ISO 8601 UTC. After this time, request a new one' },
          expiration: { type: :string, deprecated: true, example: '07-13-2020 13:41',
                        description: 'Deprecated: the expiration time formatted month-day-year, without a time zone. Read `expires_at` instead' },
          token: { type: :string,
                   example: 'eyJhbGciOiJIUzI1NaJ9.eyJ1c2VyX2lkIjoxMDYsIe9yaWdpbiI6Imh0dHA6Ly9wb2NhbGhvc3Q6MzIzMyIsImlwIjoiOjoxIiwiZXhwIjoxNTk0NjQwNTEzfQ.TyqKyKxwsnn7TZsLAfS8OTmTUPk87CSXlk6a2wQU9co', description: 'The client-side access token, that you\'ll use instead of your access token in the `token` parameter' }
        }, extras: { required: %w[token expires_at expiration] })

        it 'returns a 200 response' do |example|
          post '/api/auth/claim', params: { origin: 'http://localhost:1234', ip: '::1' }.to_json,
                                  headers: headers.merge('Authorization' => "Bearer #{user.token}")
          assert_response_matches_metadata(example.metadata)
        end

        it 'returns a 200 response with the token as a query parameter' do |example|
          post "/api/auth/claim?token=#{user.token}", params: { origin: 'http://localhost:1234', ip: '::1' }.to_json, headers: headers
          assert_response_matches_metadata(example.metadata)
        end
      end

      response '401', 'Missing or invalid account token' do
        schema Schemas::Helpers.error_schema

        it 'returns a 401 response' do |example|
          post '/api/auth/claim?token=invalid', params: { ip: '::1' }.to_json, headers: headers
          assert_response_matches_metadata(example.metadata)
        end
      end

      response '422', 'Missing origin' do
        schema Schemas::Helpers.error_schema

        it 'returns a 422 response' do |example|
          post '/api/auth/claim', params: { ip: '::1' }.to_json, headers: headers.merge('Authorization' => "Bearer #{user.token}")
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
