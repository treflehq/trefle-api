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

  path '/distributions' do

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
      security [{ token: [] }, { bearerAuth: [] }]
      parameters :zone_q, :filter_zones, :order_zones, :range_zones, :page, :per_page

      response '200', 'Success' do
        schema JsonApiHelper.array_schema(
          'zone',
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

      response '400', 'Unknown filter, filter_not, order or range key, or invalid filter value' do
        schema Schemas::Helpers.error_schema
        let(:token) { user.token }
        let(:filter) { { not_a_field: 'x' } }
        run_test!
      end

      response_too_many_requests
    end
  end

  path '/distributions/{id}' do

    get 'Retrieve a distribution zone' do
      tags 'Distributions'
      consumes 'application/json'
      produces 'application/json'
      description <<~DESC
        Get a zone by its id, its slug (the TDWG code, e.g. `fra`) or its exact name (case- and accent-insensitive, e.g. `france`).
        When the name is shared by a region and a botanical country (TDWG level 3), the country is returned.
        Unknown zones get a 404 whose message points to the `?q=` name search.
      DESC
      operationId 'getZone'
      parameter name: :id, required: true, in: :path, type: :string, description: 'The id, the slug or the exact name of the requested zone'

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

      response '404', 'Unknown zone' do
        schema Schemas::Helpers.schema_href(schema: 'error')
        let(:id) { 'atlantis' }
        let(:token) { user.token }
        run_test!
      end

      response '401', 'Invalid credentials' do
        schema Schemas::Helpers.error_schema
        let(:token) { 'invalid' }
        let(:id) { Zone.first.id }
        run_test!
      end

      response '404', 'Not found' do
        schema Schemas::Helpers.error_schema
        let(:token) { user.token }
        let(:id) { 'does-not-exist' }
        run_test!
      end

      response_too_many_requests do
        let(:id) { Zone.first.id }
      end
    end
  end

  path '/distributions/{zone_id}/species' do

    get 'List species of a distribution zone' do
      tags 'Distributions'
      consumes 'application/json'
      produces 'application/json'
      description 'List the species present in the requested zone'
      operationId 'listSpeciesZone'
      security [{ token: [] }, { bearerAuth: [] }]
      parameters :fields_species_list

      parameter name: :zone_id, required: true, in: :path, type: :string, description: 'The zone id or slug'
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

      response '400', "Unknown filter, filter_not, order or range key, invalid filter value, or page beyond #{WithCachedCount::MAX_PAGE_DEPTH}" do
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

  path '/distributions/{zone_id}/species/{id}' do

    get 'Retrieve a species of a distribution zone' do
      tags 'Distributions'
      consumes 'application/json'
      produces 'application/json'
      description 'Get one species present in the requested zone'
      operationId 'getSpeciesZone'
      security [{ token: [] }, { bearerAuth: [] }]
      parameters :fields_species

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
        # a species of that zone: the nested show answers 404 for any other
        let(:zone_id) { SpeciesDistribution.first.zone.slug }
        let(:id) { SpeciesDistribution.first.species_id }

        run_test!
      end

      response '401', 'Invalid credentials' do
        schema Schemas::Helpers.error_schema
        let(:token) { 'invalid' }
        let(:zone_id) { Zone.order(species_count: :desc).first.slug }
        let(:id) { SpeciesDistribution.first.species_id }

        run_test!
      end

      response '404', 'Not found' do
        schema Schemas::Helpers.error_schema
        let(:token) { user.token }
        let(:zone_id) { Zone.order(species_count: :desc).first.slug }
        let(:id) { 'does-not-exist' }
        run_test!
      end

      response_too_many_requests do
        let(:zone_id) { Zone.order(species_count: :desc).first.slug }
        let(:id) { SpeciesDistribution.first.species_id }
      end
    end
  end

  path '/distributions/{zone_id}/plants/{id}' do

    get 'Retrieve a plant of a distribution zone' do
      tags 'Distributions'
      consumes 'application/json'
      produces 'application/json'
      description 'Get one plant present in the requested zone'
      operationId 'getPlantZone'
      security [{ token: [] }, { bearerAuth: [] }]
      parameters :fields_plant

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
        # a species of that zone: the nested show answers 404 for any other
        let(:zone_id) { SpeciesDistribution.first.zone.slug }
        let(:id) { SpeciesDistribution.first.species.plant.slug }

        run_test!
      end

      response '401', 'Invalid credentials' do
        schema Schemas::Helpers.error_schema
        let(:token) { 'invalid' }
        let(:zone_id) { Zone.order(species_count: :desc).first.slug }
        let(:id) { SpeciesDistribution.first.species.plant.slug }

        run_test!
      end

      response '404', 'Not found' do
        schema Schemas::Helpers.error_schema
        let(:token) { user.token }
        let(:zone_id) { Zone.order(species_count: :desc).first.slug }
        let(:id) { 'does-not-exist' }
        run_test!
      end

      response_too_many_requests do
        let(:zone_id) { Zone.order(species_count: :desc).first.slug }
        let(:id) { SpeciesDistribution.first.species.plant.slug }
      end
    end
  end

end
