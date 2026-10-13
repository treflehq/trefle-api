require 'swagger_helper'

describe 'Kingdoms API' do

  before :each do
    # expect(Kingdom.count).to eq(0)
    # create(:kingdom, name: 'Plantae')
  end

  after do |example|
    JsonApiHelper.save_example(example, response)
  end

  let(:user) { create(:user) }

  path '/kingdoms' do

    get 'Searches kingdoms' do
      tags 'Kingdoms'
      consumes 'application/json'
      produces 'application/json'
      description 'List kingdoms'
      operationId 'listKingdoms'
      security [{ token: [] }, { bearerAuth: [] }]
      parameters :page, :per_page

      response '200', 'Success' do
        schema JsonApiHelper.array_schema(
          'kingdom',
          links: Schemas::Helpers.pagination_links,
          meta: Schemas::Helpers.pagination_meta
        )
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

  path '/kingdoms/{id}' do

    get 'Retrieve a kingdom' do
      tags 'Kingdoms'
      consumes 'application/json'
      produces 'application/json'
      description 'Get a kingdom'
      operationId 'getKingdom'
      parameter name: :id, required: true, in: :path, type: :string, description: 'The id or the slug of the requested kingdom'

      security [{ token: [] }, { bearerAuth: [] }]

      response '200', 'Success' do
        schema JsonApiHelper.resource_schema(
          'kingdom',
          meta: Schemas::Helpers.object_of({
            last_modified: { type: :string }
          })
        )
        let(:id) { Kingdom.first.id }
        let(:token) { user.token }

        run_test!
      end

      response '401', 'Invalid credentials' do
        schema Schemas::Helpers.error_schema
        let(:token) { 'invalid' }
        let(:id) { Kingdom.first.id }
        run_test!
      end

      response '404', 'Not found' do
        schema Schemas::Helpers.error_schema
        let(:token) { user.token }
        let(:id) { 'does-not-exist' }
        run_test!
      end

      response_too_many_requests do
        let(:id) { Kingdom.first.id }
      end
    end
  end
end
