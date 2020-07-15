require 'swagger_helper'

describe 'Subkingdoms API' do # rubocop:todo Metrics/BlockLength

  before :each do
    # expect(Subkingdom.count).to eq(0)
    # create(:subkingdom, name: 'Plantae')
  end

  after do |example|
    JsonApiHelper.save_example(example, response)
  end

  let(:user) { create(:user) }

  path '/api/v1/subkingdoms' do

    get 'Searches subkingdoms' do
      tags 'Subkingdoms'
      consumes 'application/json'
      produces 'application/json'
      description 'List subkingdoms'
      operationId 'listSubkingdoms'
      # parameter name: :id, required: true, in: :path, type: :string
      security [token: []]
      parameter name: :page, in: :query, required: false, type: :number, description: 'The page to fetch'

      response '200', 'Success' do
        schema JsonApiHelper.array_schema(
          'subkingdom',
          links: Schemas::Helpers.pagination_links,
          meta: Schemas::Helpers.object_of({
            total: { type: :integer }
          })
        )
        let(:token) { user.token }
        run_test!
      end

      response '401', 'Invalid credentials' do
        let(:token) { 'invalid' }
        run_test!
      end
    end
  end

  path '/api/v1/subkingdoms/{id}' do

    get 'Retrieve a subkingdom' do
      tags 'Subkingdoms'
      consumes 'application/json'
      produces 'application/json'
      description 'Get a subkingdom'
      operationId 'getSubkingdom'
      parameter name: :id, required: true, in: :path, type: :string, description: 'The id or the slug of the requested sub-kingdom'

      security [token: []]

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
        let(:token) { 'invalid' }
        let(:id) { Subkingdom.first.id }
        run_test!
      end
    end
  end
end
