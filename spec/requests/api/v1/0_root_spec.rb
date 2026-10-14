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

  path '/changelog' do

    get 'Data versions' do
      tags 'Root'
      produces 'application/json'
      description 'The history of the data versions, newest first (the latest 100): one entry per data operation ' \
                  '(import, migration, purge...) that may have written to the data, with the row counts it moved. ' \
                  "The current version is also in every response's `meta.dataset_version` and `X-Trefle-Data-Version` " \
                  'header. No token needed.'
      operationId 'listDataVersions'
      security []

      response '200', 'Success' do
        schema Schemas::Helpers.schema_href(schema: 'changelog')
        before do
          DataRun.create!(
            runnable: 'Spec::Run', kind: 'import', status: :completed,
            started_at: Time.utc(2026, 10, 9, 11, 0), finished_at: Time.utc(2026, 10, 9, 11, 8),
            impact: { 'species_facts' => { 'before' => 0, 'after' => 267_412, 'delta' => 267_412 } }
          )
          DatasetVersion.reset!
        end
        after { DatasetVersion.reset! }
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
