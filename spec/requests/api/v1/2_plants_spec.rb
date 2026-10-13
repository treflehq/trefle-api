require 'swagger_helper'

describe 'Plants API' do

  before :each do
    # expect(Plant.count).to eq(0)
    # create(:plant, name: 'Plantae')
  end

  after do |example|
    JsonApiHelper.save_example(example, response)
  end

  let(:user) { create(:user) }

  path '/plants' do

    get 'List plants' do
      tags 'Plants'
      consumes 'application/json'
      produces 'application/json'
      description 'List plants'
      operationId 'listPlants'
      security [{ token: [] }, { bearerAuth: [] }]

      parameters :filter_species, :filter_not_species, :order_species, :range_species, :page, :per_page

      response '200', 'Success' do
        schema JsonApiHelper.array_schema(
          'species_light',
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

      response '400', 'Unknown filter, filter_not, order or range key, filter value outside the accepted values, ' \
                      "inverted or non-numeric range, or page beyond #{WithCachedCount::MAX_PAGE_DEPTH}" do
        schema Schemas::Helpers.error_schema
        let(:token) { user.token }
        let(:filter) { { not_a_field: 'x' } }
        run_test!
      end

      response_too_many_requests
    end
  end

  path '/plants/{id}' do

    get 'Retrieve a plant' do
      tags 'Plants'
      consumes 'application/json'
      produces 'application/json'
      description 'Get a plant'
      operationId 'getPlant'
      parameter name: :id, required: true, in: :path, type: :string, description: 'The id or the slug of the requested plant'

      security [{ token: [] }, { bearerAuth: [] }]

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
        schema Schemas::Helpers.error_schema
        let(:token) { 'invalid' }
        let(:id) { Plant.order(completion_ratio: :desc).first.slug }
        run_test!
      end

      response '404', 'Not found' do
        schema Schemas::Helpers.error_schema
        let(:token) { user.token }
        let(:id) { 'does-not-exist' }
        run_test!
      end

      response_too_many_requests do
        let(:id) { Plant.order(completion_ratio: :desc).first.slug }
      end
    end
  end

  path '/plants/search' do

    get 'Search for a plant' do
      tags 'Plants'
      consumes 'application/json'
      produces 'application/json'
      description 'Search for a plant with the given scientific name, common name, synonym name etc.'
      operationId 'searchPlants'
      parameters :q, :page, :per_page, :filter_species, :filter_not_species, :order_species, :range_species

      security [{ token: [] }, { bearerAuth: [] }]

      response '200', 'Success' do
        schema JsonApiHelper.array_schema(
          'species_light',
          links: Schemas::Helpers.pagination_links,
          meta: Schemas::Helpers.pagination_meta
        )
        let(:q) { 'cocos' }
        let(:token) { user.token }

        run_test!
      end

      response '401', 'Invalid credentials' do
        schema Schemas::Helpers.error_schema
        let(:token) { 'invalid' }
        let(:q) { 'cocos' }
        # puts "Running with token=#{token} & q=#{q}"
        run_test!
      end

      response '422', 'Missing search query' do
        schema Schemas::Helpers.error_schema
        let(:token) { user.token }
        let(:q) { '' }
        run_test!
      end

      response_too_many_requests do
        let(:q) { 'cocos' }
      end
    end
  end

  path '/plants/{id}/report' do

    post 'Report an error' do

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

      security [{ token: [] }, { bearerAuth: [] }]

      response '201', 'Success' do
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
        schema Schemas::Helpers.error_schema
        let(:token) { 'invalid' }
        let(:id) { Species.where(complete_data: true).first.id }
        run_test!
      end

      response '404', 'Not found' do
        schema Schemas::Helpers.error_schema
        let(:token) { user.token }
        let(:id) { 'does-not-exist' }
        run_test!
      end

      response_too_many_requests do
        let(:id) { Species.where(complete_data: true).first.id }
      end
    end
  end

  path '/distributions/{zone_id}/plants' do

    get 'List plants in a distribution zone' do
      tags 'Plants'
      consumes 'application/json'
      produces 'application/json'
      description 'List all the plants in the requested zone.'
      operationId 'listPlantsZone'
      security [{ token: [] }, { bearerAuth: [] }]

      parameter name: :zone_id, required: true, in: :path, type: :string, description: 'The zone id or twdg code'
      parameters :filter_species, :filter_not_species, :order_species, :range_species, :page, :per_page

      response '200', 'Success' do
        schema JsonApiHelper.array_schema(
          'species_light',
          links: Schemas::Helpers.pagination_links,
          meta: Schemas::Helpers.pagination_meta
        )
        let(:token) { user.token }
        let(:zone_id) { Zone.order(species_count: :desc).first.slug }
        run_test!
      end

      response '401', 'Invalid credentials' do
        schema Schemas::Helpers.error_schema
        let(:token) { 'invalid' }
        let(:zone_id) { Zone.order(species_count: :desc).first.slug }
        run_test!
      end

      response '400', 'Unknown filter, filter_not, order or range key, filter value outside the accepted values, ' \
                      "inverted or non-numeric range, or page beyond #{WithCachedCount::MAX_PAGE_DEPTH}" do
        schema Schemas::Helpers.error_schema
        let(:token) { user.token }
        let(:zone_id) { Zone.order(species_count: :desc).first.slug }
        let(:filter) { { not_a_field: 'x' } }
        run_test!
      end

      response '404', 'Not found' do
        schema Schemas::Helpers.error_schema
        let(:token) { user.token }
        let(:zone_id) { 'does-not-exist' }
        run_test!
      end

      response_too_many_requests do
        let(:zone_id) { Zone.order(species_count: :desc).first.slug }
      end
    end
  end

  path '/genus/{genus_id}/plants' do

    get 'List plants of a genus' do
      tags 'Plants'
      consumes 'application/json'
      produces 'application/json'
      description 'List plants of the requested genus'
      operationId 'listPlantsGenus'
      security [{ token: [] }, { bearerAuth: [] }]

      parameter name: :genus_id, required: true, in: :path, type: :string, description: 'The genus id or slug'
      parameters :filter_species, :filter_not_species, :order_species, :range_species, :page, :per_page

      response '200', 'Success' do
        schema JsonApiHelper.array_schema(
          'species_light',
          links: Schemas::Helpers.pagination_links,
          meta: Schemas::Helpers.pagination_meta
        )
        let(:token) { user.token }
        let(:genus_id) { Plant.order(completion_ratio: :desc).first.genus.slug }

        run_test!
      end

      response '401', 'Invalid credentials' do
        schema Schemas::Helpers.error_schema
        let(:token) { 'invalid' }
        let(:genus_id) { Plant.order(completion_ratio: :desc).first.genus.slug }

        run_test!
      end

      response '400', 'Unknown filter, filter_not, order or range key, filter value outside the accepted values, ' \
                      "inverted or non-numeric range, or page beyond #{WithCachedCount::MAX_PAGE_DEPTH}" do
        schema Schemas::Helpers.error_schema
        let(:token) { user.token }
        let(:genus_id) { Plant.order(completion_ratio: :desc).first.genus.slug }
        let(:filter) { { not_a_field: 'x' } }
        run_test!
      end

      response '404', 'Not found' do
        schema Schemas::Helpers.error_schema
        let(:token) { user.token }
        let(:genus_id) { 'does-not-exist' }
        run_test!
      end

      response_too_many_requests do
        let(:genus_id) { Plant.order(completion_ratio: :desc).first.genus.slug }
      end
    end
  end

  path '/plants/{plant_id}/species' do

    get 'List species of a plant' do
      tags 'Plants'
      consumes 'application/json'
      produces 'application/json'
      description 'List the species attached to the requested plant'
      operationId 'listSpeciesPlant'
      security [{ token: [] }, { bearerAuth: [] }]

      parameter name: :plant_id, required: true, in: :path, type: :string, description: 'The plant id or slug'
      parameters :filter_species, :filter_not_species, :order_species, :range_species, :page, :per_page

      response '200', 'Success' do
        schema JsonApiHelper.array_schema(
          'species_light',
          links: Schemas::Helpers.pagination_links,
          meta: Schemas::Helpers.pagination_meta
        )
        let(:token) { user.token }
        let(:plant_id) { Species.where(complete_data: true).first.plant.slug }

        run_test!
      end

      response '401', 'Invalid credentials' do
        schema Schemas::Helpers.error_schema
        let(:token) { 'invalid' }
        let(:plant_id) { Species.where(complete_data: true).first.plant.slug }

        run_test!
      end

      response '400', 'Unknown filter, filter_not, order or range key, filter value outside the accepted values, ' \
                      "inverted or non-numeric range, or page beyond #{WithCachedCount::MAX_PAGE_DEPTH}" do
        schema Schemas::Helpers.error_schema
        let(:token) { user.token }
        let(:plant_id) { Species.where(complete_data: true).first.plant.slug }
        let(:filter) { { not_a_field: 'x' } }
        run_test!
      end

      response '404', 'Not found' do
        schema Schemas::Helpers.error_schema
        let(:token) { user.token }
        let(:plant_id) { 'does-not-exist' }
        run_test!
      end

      response_too_many_requests do
        let(:plant_id) { Species.where(complete_data: true).first.plant.slug }
      end
    end
  end

  path '/plants/{plant_id}/species/{id}' do

    get 'Retrieve a species of a plant' do
      tags 'Plants'
      consumes 'application/json'
      produces 'application/json'
      description 'Get one species attached to the requested plant'
      operationId 'getSpeciesPlant'
      security [{ token: [] }, { bearerAuth: [] }]

      parameter name: :plant_id, required: true, in: :path, type: :string, description: 'The plant id or slug'
      parameter name: :id, required: true, in: :path, type: :string, description: 'The id or the slug of the requested record'

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
        let(:token) { user.token }
        let(:plant_id) { Species.where(complete_data: true).first.plant.slug }
        let(:id) { Species.where(complete_data: true).first.id }

        run_test!
      end

      response '401', 'Invalid credentials' do
        schema Schemas::Helpers.error_schema
        let(:token) { 'invalid' }
        let(:plant_id) { Species.where(complete_data: true).first.plant.slug }
        let(:id) { Species.where(complete_data: true).first.id }

        run_test!
      end

      response '404', 'Not found' do
        schema Schemas::Helpers.error_schema
        let(:token) { user.token }
        let(:plant_id) { Species.where(complete_data: true).first.plant.slug }
        let(:id) { 'does-not-exist' }
        run_test!
      end

      response_too_many_requests do
        let(:plant_id) { Species.where(complete_data: true).first.plant.slug }
        let(:id) { Species.where(complete_data: true).first.id }
      end
    end
  end

  path '/genus/{genus_id}/plants/{id}' do

    get 'Retrieve a plant of a genus' do
      tags 'Plants'
      consumes 'application/json'
      produces 'application/json'
      description 'Get one plant of the requested genus'
      operationId 'getPlantGenus'
      security [{ token: [] }, { bearerAuth: [] }]

      parameter name: :genus_id, required: true, in: :path, type: :string, description: 'The genus id or slug'
      parameter name: :id, required: true, in: :path, type: :string, description: 'The id or the slug of the requested record'

      response '200', 'Success' do
        schema JsonApiHelper.resource_schema(
          'plant',
          meta: Schemas::Helpers.object_of({
            last_modified: { type: :string },
            images_count: { type: :integer },
            sources_count: { type: :integer },
            synonyms_count: { type: :integer }
          })
        )
        let(:token) { user.token }
        let(:genus_id) { Plant.order(completion_ratio: :desc).first.genus.slug }
        let(:id) { Plant.order(completion_ratio: :desc).first.id }

        run_test!
      end

      response '401', 'Invalid credentials' do
        schema Schemas::Helpers.error_schema
        let(:token) { 'invalid' }
        let(:genus_id) { Plant.order(completion_ratio: :desc).first.genus.slug }
        let(:id) { Plant.order(completion_ratio: :desc).first.id }

        run_test!
      end

      response '404', 'Not found' do
        schema Schemas::Helpers.error_schema
        let(:token) { user.token }
        let(:genus_id) { Plant.order(completion_ratio: :desc).first.genus.slug }
        let(:id) { 'does-not-exist' }
        run_test!
      end

      response_too_many_requests do
        let(:genus_id) { Plant.order(completion_ratio: :desc).first.genus.slug }
        let(:id) { Plant.order(completion_ratio: :desc).first.id }
      end
    end
  end

end
