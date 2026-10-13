require 'swagger_helper'

describe 'Subkingdoms API' do

  before :each do
    # expect(Subkingdom.count).to eq(0)
    # create(:subkingdom, name: 'Plantae')
  end

  after do |example|
    JsonApiHelper.save_example(example, response)
  end

  let(:user) { create(:user) }

  path '/subkingdoms' do

    get 'Searches subkingdoms' do
      tags 'Subkingdoms'
      consumes 'application/json'
      produces 'application/json'
      description 'List subkingdoms'
      operationId 'listSubkingdoms'
      security [{ token: [] }, { bearerAuth: [] }]
      parameters :page, :per_page

      response '200', 'Success' do
        schema JsonApiHelper.array_schema(
          'subkingdom',
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

  path '/subkingdoms/{id}' do

    get 'Retrieve a subkingdom' do
      tags 'Subkingdoms'
      consumes 'application/json'
      produces 'application/json'
      description 'Get a subkingdom'
      operationId 'getSubkingdom'
      parameter name: :id, required: true, in: :path, type: :string, description: 'The id or the slug of the requested sub-kingdom'

      security [{ token: [] }, { bearerAuth: [] }]

      response '200', 'Success' do
        schema JsonApiHelper.resource_schema(
          'subkingdom',
          meta: Schemas::Helpers.object_of({
            last_modified: { type: :string }
          })
        )
        let(:id) { Subkingdom.first.id }
        let(:token) { user.token }

        run_test!
      end

      response '401', 'Invalid credentials' do
        schema Schemas::Helpers.error_schema
        let(:token) { 'invalid' }
        let(:id) { Subkingdom.first.id }
        run_test!
      end

      response '404', 'Not found' do
        schema Schemas::Helpers.error_schema
        let(:token) { user.token }
        let(:id) { 'does-not-exist' }
        run_test!
      end

      response_too_many_requests do
        let(:id) { Subkingdom.first.id }
      end
    end
  end
end
