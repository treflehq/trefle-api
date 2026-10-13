require 'swagger_helper'

describe 'Root API' do

  after do |example|
    JsonApiHelper.save_example(example, response)
  end

  let(:user) { create(:user) }

  path '/' do

    get 'API status' do
      tags 'Root'
      produces 'application/json'
      description 'Public database counters. With the OpenAPI document, the only endpoint that does not require a token.'
      operationId 'getApiStatus'
      # Explicitly no authentication, rather than merely omitting the key.
      security []

      response '200', 'Success' do
        schema Schemas::Helpers.schema_href(schema: 'api_status')
        run_test!
      end

      response_too_many_requests
    end
  end

  path '/me' do

    get 'Retrieve the token owner' do
      tags 'Root'
      produces 'application/json'
      description 'The profile of the account the token belongs to. `name`, `email` and `created_at` are null when authenticating with a JWT.'
      operationId 'getMe'
      security [{ token: [] }, { bearerAuth: [] }]

      response '200', 'Success' do
        schema Schemas::Helpers.schema_href(schema: 'user_profile')
        let(:token) { user.token }
        run_test!
      end

      response '401', 'Invalid credentials' do
        schema Schemas::Helpers.error_schema
        let(:token) { 'invalid' }
        run_test!
      end

      response_too_many_requests
    end
  end
end
