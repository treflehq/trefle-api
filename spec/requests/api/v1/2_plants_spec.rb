require 'swagger_helper'

describe 'Plants API' do # rubocop:todo Metrics/BlockLength

  before :each do
    # expect(Plant.count).to eq(0)
    # create(:plant, name: 'Plantae')
  end

  after do |example|
    JsonApiHelper.save_example(example, response)
  end

  let(:user) { create(:user) }

  path '/api/v1/plants' do

    get 'List plants' do
      tags 'Plants'
      consumes 'application/json'
      produces 'application/json'
      description 'List plants'
      operationId 'listPlants'
      security [token: []]

      parameter name: :filter, in: :query, required: false, type: :object, description: 'Filter on values', schema: Schemas::Helpers.schema_href(schema: 'filters_species')
      parameter name: :filter_not, in: :query, required: false, type: :object, description: 'Exclude results matching null values', schema: Schemas::Helpers.schema_href(schema: 'filters_not_species')
      parameter name: :order, in: :query, required: false, type: :object, description: 'Sort on values', schema: Schemas::Helpers.schema_href(schema: 'sorts_species')
      parameter name: :range, in: :query, required: false, type: :object, description: 'Range on values', schema: Schemas::Helpers.schema_href(schema: 'ranges_species')
      # parameter name: :q, in: :query, required: false, type: :string, description: 'Search for plants matching the given query'
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

  path '/api/v1/plants/{id}' do

    get 'Retrieve a plant' do
      tags 'Plants'
      consumes 'application/json'
      produces 'application/json'
      description 'Get a plant'
      operationId 'getPlant'
      parameter name: :id, required: true, in: :path, type: :string, description: 'The id or the slug of the requested plant'

      security [token: []]

      response '200', 'Success' do
        schema JsonApiHelper.resource_schema(
          'plant',
          meta: Schemas::Helpers.object_of({
            last_modified: { type: :string }
          })
        )
        let(:id) { Plant.order(completion_ratio: :desc).first.slug }
        let(:token) { user.token }

        run_test!
      end

      response '401', 'Invalid credentials' do
        let(:token) { 'invalid' }
        let(:id) { Plant.order(completion_ratio: :desc).first.slug }
        run_test!
      end
    end
  end

  path '/api/v1/plants/search' do

    get 'Search for a plant' do
      tags 'Plants'
      consumes 'application/json'
      produces 'application/json'
      description 'Search for a plant with the given scientific name, common name, synonym name etc.'
      operationId 'searchPlants'
      parameter name: :q, required: true, in: :query, type: :string, description: 'The string to search'
      parameter name: :page, in: :query, required: false, type: :number, description: 'The page to fetch'
      parameter name: :filter, in: :query, required: false, type: :object, description: 'Filter on values', schema: Schemas::Helpers.schema_href(schema: 'filters_plants')
      parameter name: :filter_not, in: :query, required: false, type: :object, description: 'Exclude results matching null values', schema: Schemas::Helpers.schema_href(schema: 'filters_not_species')
      parameter name: :order, in: :query, required: false, type: :object, description: 'Sort on values', schema: Schemas::Helpers.schema_href(schema: 'sorts_plants')
      parameter name: :range, in: :query, required: false, type: :object, description: 'Range on values', schema: Schemas::Helpers.schema_href(schema: 'ranges_plants')

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
        # puts "Running with token=#{token} & q=#{q}"
        # run_test!
      end
    end
  end

  path '/api/v1/plants/{id}/report' do # rubocop:todo Metrics/BlockLength

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

      tags 'Plants'
      consumes 'application/json'
      produces 'application/json'
      description 'A short API call to report an error regarding a plant entry'
      operationId 'reportPlants'
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

  path '/api/v1/distributions/{zone_id}/plants' do

    get 'List plants in a distribution zone' do
      tags 'Plants'
      consumes 'application/json'
      produces 'application/json'
      description 'List all the plants in the requested zone.'
      operationId 'listPlantsZone'
      security [token: []]

      parameter name: :zone_id, required: true, in: :path, type: :string, description: 'The zone id or twdg code'
      parameter name: :filter, in: :query, required: false, type: :object, description: 'Filter on values', schema: Schemas::Helpers.schema_href(schema: 'filters_species')
      parameter name: :filter_not, in: :query, required: false, type: :object, description: 'Exclude results matching null values', schema: Schemas::Helpers.schema_href(schema: 'filters_not_species')
      parameter name: :order, in: :query, required: false, type: :object, description: 'Sort on values', schema: Schemas::Helpers.schema_href(schema: 'sorts_species')
      parameter name: :range, in: :query, required: false, type: :object, description: 'Range on values', schema: Schemas::Helpers.schema_href(schema: 'ranges_species')
      # parameter name: :q, in: :query, required: false, type: :string, description: 'Search for plants matching the given query'
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
        let(:zone_id) { Zone.order(species_count: :desc).first.slug }
        run_test!
      end

      response '401', 'Invalid credentials' do
        let(:token) { 'invalid' }
        let(:zone_id) { Zone.order(species_count: :desc).first.slug }
        run_test!
      end
    end
  end

  path '/api/v1/genus/{genus_id}/plants' do

    get 'List plants of a genus' do
      tags 'Plants'
      consumes 'application/json'
      produces 'application/json'
      description 'List plants of the requested genus'
      operationId 'listPlantsGenus'
      security [token: []]

      parameter name: :genus_id, required: true, in: :path, type: :string, description: 'The genus id or slug'
      parameter name: :filter, in: :query, required: false, type: :object, description: 'Filter on values', schema: Schemas::Helpers.schema_href(schema: 'filters_species')
      parameter name: :filter_not, in: :query, required: false, type: :object, description: 'Exclude results matching null values', schema: Schemas::Helpers.schema_href(schema: 'filters_not_species')
      parameter name: :order, in: :query, required: false, type: :object, description: 'Sort on values', schema: Schemas::Helpers.schema_href(schema: 'sorts_species')
      parameter name: :range, in: :query, required: false, type: :object, description: 'Range on values', schema: Schemas::Helpers.schema_href(schema: 'ranges_species')
      # parameter name: :q, in: :query, required: false, type: :string, description: 'Search for plants matching the given query'
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
        let(:genus_id) { Plant.order(completion_ratio: :desc).first.genus.slug }

        run_test!
      end

      response '401', 'Invalid credentials' do
        let(:token) { 'invalid' }
        let(:genus_id) { Plant.order(completion_ratio: :desc).first.genus.slug }

        run_test!
      end
    end
  end
end
