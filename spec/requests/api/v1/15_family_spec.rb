require 'swagger_helper'

describe 'Families API' do # rubocop:todo Metrics/BlockLength

  before :each do
    # expect(Family.count).to eq(0)
    # create(:family, name: 'Plantae')
  end

  after do |example|
    JsonApiHelper.save_example(example, response)
  end

  let(:user) { create(:user) }

  path '/api/v1/families' do

    get 'Searches families' do
      tags 'Families'
      consumes 'application/json'
      produces 'application/json'
      description 'List families'
      operationId 'listFamilies'
      # parameter name: :id, required: true, in: :path, type: :string
      security [token: []]
      parameter name: :page, in: :query, required: false, type: :number, description: 'The page to fetch'
      parameter name: :filter, in: :query, required: false, description: 'Filter on values', schema: Schemas::Helpers.schema_href(schema: 'filters_families')
      parameter name: :order, in: :query, required: false, description: 'Sort on values', schema: Schemas::Helpers.schema_href(schema: 'sorts_families')
      # parameter name: :q, in: :query, required: false, type: :string, description: 'Search for family names matching the given query'

      response '200', 'Success' do
        schema JsonApiHelper.array_schema(
          'family',
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

  path '/api/v1/families/{id}' do

    get 'Retrieve a family' do
      tags 'Families'
      consumes 'application/json'
      produces 'application/json'
      description 'Get a family'
      operationId 'getFamily'
      parameter name: :id, required: true, in: :path, type: :string, description: 'The id or the slug of the requested family'

      security [token: []]

      response '200', 'Success' do
        schema JsonApiHelper.resource_schema(
          'family',
          meta: Schemas::Helpers.object_of({
            last_modified: { type: :string }
          })
        )
        let(:id) { Family.first.id }
        let(:token) { user.token }

        run_test!
      end

      response '401', 'Invalid credentials' do
        let(:token) { 'invalid' }
        let(:id) { Family.first.id }
        run_test!
      end
    end
  end
end
