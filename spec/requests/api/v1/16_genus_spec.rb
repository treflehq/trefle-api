require 'swagger_helper'

describe 'Genus API' do # rubocop:todo Metrics/BlockLength

  COLLECTION_SCHEMA = JsonApiHelper.array_schema(
    'genus',
    links: Schemas::Helpers.pagination_links,
    meta: Schemas::Helpers.object_of({
      total: { type: :integer }
    })
  )

  before :each do
    # expect(Genus.count).to eq(0)
    # create(:genus, name: 'Plantae')
  end

  after do |example|
    JsonApiHelper.save_example(example, response)
  end

  let(:user) { create(:user) }

  path '/api/v1/genus' do

    get 'Searches genus' do
      tags 'Genus'
      consumes 'application/json'
      produces 'application/json'
      description 'List genus'
      operationId 'listGenus'

      parameter name: :filter, in: :query, required: false, type: :object, description: 'Filter on values', schema: Schemas::Helpers.schema_href(schema: 'filters_genus')
      parameter name: :sort, in: :query, required: false, type: :object, description: 'Sort on values', schema: Schemas::Helpers.schema_href(schema: 'sorts_genus')
      # parameter name: :q, in: :query, required: false, type: :string, description: 'Search for genus names matching the given query'
      parameter name: :page, in: :query, required: false, type: :number, description: 'The page to fetch'

      security [token: []]

      response '200', 'Success' do
        schema COLLECTION_SCHEMA
        let(:token) { user.token }
        run_test!
      end

      # response '200', 'Filter on name' do
      #   # schema COLLECTION_SCHEMA
      #   let(:token) { user.token }
      #   let(:slug) { Genus.all.sample.slug }
      #   run_test!
      # end

      response '401', 'Invalid credentials' do
        let(:token) { 'invalid' }
        run_test!
      end
    end
  end

  path '/api/v1/genus/{id}' do

    get 'Retrieve a genus' do
      tags 'Genus'
      consumes 'application/json'
      produces 'application/json'
      description 'Get a genus'
      operationId 'getGenus'
      parameter name: :id, required: true, in: :path, type: :string, description: 'The id or the slug of the requested genus'

      security [token: []]

      response '200', 'Success' do
        schema JsonApiHelper.resource_schema(
          'genus',
          meta: Schemas::Helpers.object_of({
            last_modified: { type: :string }
          })
        )
        let(:id) { Genus.first.id }
        let(:token) { user.token }

        run_test!
      end

      response '401', 'Invalid credentials' do
        let(:token) { 'invalid' }
        let(:id) { Genus.first.id }
        run_test!
      end
    end
  end
end
