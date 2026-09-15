require 'swagger_helper'

describe 'Distributions API' do

  before :each do
    # expect(Zone.count).to eq(0)
    # create(:zone, name: 'Plantae')
  end

  after do |example|
    JsonApiHelper.save_example(example, response)
  end

  let(:user) { create(:user) }

  path '/api/v1/distributions' do

    get 'List distributions zones' do
      tags 'Distributions'
      consumes 'application/json'
      produces 'application/json'
      description <<~DESC
        List distributions zones. Zones are following the WGSRPD convention.

        WGSRPD provides an agreed system of geographical units at approximately "country" level and upwards for use in recording plant distributions. It allows adopting organizations to compare and exchange data with each other without loss of information due to incompatible geographical boundaries.

        [Read more on the TDWG website](https://www.tdwg.org/standards/wgsrpd/).
      DESC

      operationId 'listDistributions'
      # parameter name: :id, required: true, in: :path, type: :string
      security [{ token: [] }, { bearerAuth: [] }]
      parameter name: :page, in: :query, required: false, type: :number, description: 'The page to fetch'

      response '200', 'Success' do
        schema JsonApiHelper.array_schema(
          'zone',
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

  path '/api/v1/distributions/{id}' do

    get 'Retrieve a distribution zone' do
      tags 'Distributions'
      consumes 'application/json'
      produces 'application/json'
      description 'Get a zone'
      operationId 'getZone'
      parameter name: :id, required: true, in: :path, type: :string, description: 'The id or the slug of the requested zone'

      security [{ token: [] }, { bearerAuth: [] }]

      response '200', 'Success' do
        schema JsonApiHelper.resource_schema(
          'zone',
          meta: Schemas::Helpers.object_of({
            last_modified: { type: :string }
          })
        )
        let(:id) { Zone.first.id }
        let(:token) { user.token }

        run_test!
      end

      response '401', 'Invalid credentials' do
        let(:token) { 'invalid' }
        let(:id) { Zone.first.id }
        run_test!
      end
    end
  end

  path '/api/v1/distributions/{zone_id}/species' do

    get 'List species of a distribution zone' do
      tags 'Distributions'
      consumes 'application/json'
      produces 'application/json'
      description 'List the species present in the requested zone'
      operationId 'listSpeciesZone'
      security [{ token: [] }, { bearerAuth: [] }]

      parameter name: :zone_id, required: true, in: :path, type: :string, description: 'The zone id or slug'
      parameter name: :filter, in: :query, required: false, description: 'Filter on values', schema: Schemas::Helpers.schema_href(schema: 'filters_species')
      parameter name: :filter_not, in: :query, required: false, description: 'Exclude results matching null values',
                schema: Schemas::Helpers.schema_href(schema: 'filters_not_species')
      parameter name: :order, in: :query, required: false, description: 'Sort on values', schema: Schemas::Helpers.schema_href(schema: 'sorts_species')
      parameter name: :range, in: :query, required: false, description: 'Range on values', schema: Schemas::Helpers.schema_href(schema: 'ranges_species')
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

  path '/api/v1/distributions/{zone_id}/species/{id}' do

    get 'Retrieve a species of a distribution zone' do
      tags 'Distributions'
      consumes 'application/json'
      produces 'application/json'
      description 'Get one species present in the requested zone'
      operationId 'getSpeciesZone'
      security [{ token: [] }, { bearerAuth: [] }]

      parameter name: :zone_id, required: true, in: :path, type: :string, description: 'The zone id or slug'
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
        let(:zone_id) { Zone.order(species_count: :desc).first.slug }
        let(:id) { SpeciesDistribution.first.species_id }

        run_test!
      end

      response '401', 'Invalid credentials' do
        let(:token) { 'invalid' }
        let(:zone_id) { Zone.order(species_count: :desc).first.slug }
        let(:id) { SpeciesDistribution.first.species_id }

        run_test!
      end
    end
  end

  path '/api/v1/distributions/{zone_id}/plants/{id}' do

    get 'Retrieve a plant of a distribution zone' do
      tags 'Distributions'
      consumes 'application/json'
      produces 'application/json'
      description 'Get one plant present in the requested zone'
      operationId 'getPlantZone'
      security [{ token: [] }, { bearerAuth: [] }]

      parameter name: :zone_id, required: true, in: :path, type: :string, description: 'The zone id or slug'
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
        let(:zone_id) { Zone.order(species_count: :desc).first.slug }
        let(:id) { SpeciesDistribution.first.species.plant.slug }

        run_test!
      end

      response '401', 'Invalid credentials' do
        let(:token) { 'invalid' }
        let(:zone_id) { Zone.order(species_count: :desc).first.slug }
        let(:id) { SpeciesDistribution.first.species.plant.slug }

        run_test!
      end
    end
  end

end
