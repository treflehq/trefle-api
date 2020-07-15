require 'swagger_helper'

describe 'Species API' do # rubocop:todo Metrics/BlockLength

  before :each do
    # expect(Species.count).to eq(0)
    # create(:species, name: 'Speciesae')
  end

  after do |example|
    JsonApiHelper.save_example(example, response)
  end

  let(:user) { create(:user) }

  path '/api/v1/species' do

    get 'List species' do
      tags 'Species'
      consumes 'application/json'
      produces 'application/json'
      description 'List species'
      operationId 'listSpecies'
      security [token: []]

      parameter name: :filter, in: :query, required: false, type: :object, description: 'Filter on values', schema: Schemas::Helpers.schema_href(schema: 'filters_species')
      parameter name: :filter_not, in: :query, required: false, type: :object, description: 'Exclude results matching null values', schema: Schemas::Helpers.schema_href(schema: 'filters_not_species')
      parameter name: :sort, in: :query, required: false, type: :object, description: 'Sort on values', schema: Schemas::Helpers.schema_href(schema: 'sorts_species')
      parameter name: :range, in: :query, required: false, type: :object, description: 'Range on values', schema: Schemas::Helpers.schema_href(schema: 'ranges_species')
      # parameter name: :q, in: :query, required: false, type: :string, description: 'Search for species matching the given query'

      parameter name: :page, in: :query, required: false, type: :number, description: 'The page to fetch'

      response '200', 'Success' do
        schema JsonApiHelper.array_schema(
          'species_light',
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

  path '/api/v1/species/{id}' do

    get 'Retrieve a species' do
      tags 'Species'
      consumes 'application/json'
      produces 'application/json'
      description 'Get a species'
      operationId 'getSpecies'
      parameter name: :id, required: true, in: :path, type: :string, description: 'The id or the slug of the requested species'

      security [token: []]

      response '200', 'Success' do
        schema JsonApiHelper.resource_schema(
          'species',
          meta: Schemas::Helpers.object_of({
            last_modified: { type: :string },
            images_count: { type: :integer },
            sources_count: { type: :integer },
            synonyms_count: { type: :integer }
          })
        )
        let(:id) { Species.where(complete_data: true).first.id }
        let(:token) { user.token }

        run_test!
      end

      response '401', 'Invalid credentials' do
        let(:token) { 'invalid' }
        let(:id) { Species.where(complete_data: true).first.id }
        run_test!
      end
    end
  end

  path '/api/v1/species/search' do

    get 'Search a species' do
      tags 'Species'
      consumes 'application/json'
      produces 'application/json'
      description 'Search a species'
      operationId 'searchSpecies'
      parameter name: :q, required: true, in: :query, type: :string, description: 'The string to search'
      parameter name: :page, in: :query, required: false, type: :number, description: 'The page to fetch'

      security [token: []]

      response '200', 'Success' do
        schema JsonApiHelper.array_schema(
          'species_light',
          links: Schemas::Helpers.pagination_links,
          meta: Schemas::Helpers.object_of({
            total: { type: :integer }
          })
        )
        let(:q) { 'cocos' }
        let(:token) { user.token }

        run_test!
      end

      response '401', 'Invalid credentials' do
        let(:token) { 'invalid' }
        let(:q) { 'cocos' }
        # run_test!
      end
    end
  end

  path '/api/v1/species/{id}/report' do # rubocop:todo Metrics/BlockLength

    post 'Report an error' do # rubocop:todo Metrics/BlockLength

      noteSchema = { # rubocop:todo Naming/VariableName
        type: :object,
        properties: {
          notes: {
            type: 'string',
            example: 'The flower color is red',
            description: 'An optional note about the incorrect data'
          }
        }
      }

      tags 'Species'
      consumes 'application/json'
      produces 'application/json'
      description 'A short API call to report an error regarding a species entry'
      operationId 'reportSpecies'
      # rubocop:todo Naming/VariableName
      parameter name: :notes, required: false, in: :body, schema: noteSchema, description: 'An optional note about the incorrect data'
      # rubocop:enable Naming/VariableName
      parameter name: :id, required: true, in: :path, type: :string, description: 'The id or the slug of the requested species'

      security [token: []]

      response '200', 'Success' do
        schema JsonApiHelper.resource_schema(
          'correction',
          meta: Schemas::Helpers.object_of({
            last_modified: { type: :string }
          })
        )
        let(:id) { Species.where(complete_data: true).first.id }
        let(:notes) { { notes: 'The flower color is red' } }
        let(:token) { user.token }

        run_test!
      end

      response '401', 'Invalid credentials' do
        let(:token) { 'invalid' }
        let(:id) { Species.where(complete_data: true).first.id }
        run_test!
      end
    end
  end
end
