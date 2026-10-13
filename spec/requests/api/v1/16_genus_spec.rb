require 'swagger_helper'

describe 'Genus API' do

  collection_schema = JsonApiHelper.array_schema(
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

  path '/genus' do

    get 'Searches genus' do
      tags 'Genus'
      consumes 'application/json'
      produces 'application/json'
      description 'List genus'
      operationId 'listGenus'

      parameters :filter_genus, :order_genus, :page, :per_page

      security [{ token: [] }, { bearerAuth: [] }]

      response '200', 'Success' do
        schema collection_schema
        let(:token) { user.token }
        run_test!
      end

      # response '200', 'Filter on name' do
      #   # schema collection_schema
      #   let(:token) { user.token }
      #   let(:slug) { Genus.all.sample.slug }
      #   run_test!
      # end

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

  path '/genus/{id}' do

    get 'Retrieve a genus' do
      tags 'Genus'
      consumes 'application/json'
      produces 'application/json'
      description 'Get a genus'
      operationId 'getGenus'
      parameter name: :id, required: true, in: :path, type: :string, description: 'The id or the slug of the requested genus'

      security [{ token: [] }, { bearerAuth: [] }]

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
        schema Schemas::Helpers.error_schema
        let(:token) { 'invalid' }
        let(:id) { Genus.first.id }
        run_test!
      end

      response '404', 'Not found' do
        schema Schemas::Helpers.error_schema
        let(:token) { user.token }
        let(:id) { 'does-not-exist' }
        run_test!
      end

      response_too_many_requests do
        let(:id) { Genus.first.id }
      end
    end
  end

  path '/genus/{genus_id}/species' do

    get 'List species of a genus' do
      tags 'Genus'
      consumes 'application/json'
      produces 'application/json'
      description 'List the species of the requested genus'
      operationId 'listSpeciesGenus'
      security [{ token: [] }, { bearerAuth: [] }]

      parameter name: :genus_id, required: true, in: :path, type: :string, description: 'The genus id or slug'
      parameters :filter_species, :filter_not_species, :order_species, :range_species, :page, :per_page

      response '200', 'Success' do
        schema JsonApiHelper.array_schema(
          'species_light',
          links: Schemas::Helpers.pagination_links,
          meta: Schemas::Helpers.object_of({
            total: { type: :integer }
          })
        )
        let(:token) { user.token }
        let(:genus_id) { Species.where(complete_data: true).first.genus.slug }

        run_test!
      end

      response '401', 'Invalid credentials' do
        schema Schemas::Helpers.error_schema
        let(:token) { 'invalid' }
        let(:genus_id) { Species.where(complete_data: true).first.genus.slug }

        run_test!
      end

      response '400', "Unknown filter, filter_not, order or range key, invalid filter value, or page beyond #{WithCachedCount::MAX_PAGE_DEPTH}" do
        schema Schemas::Helpers.error_schema
        let(:token) { user.token }
        let(:genus_id) { Species.where(complete_data: true).first.genus.slug }
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
        let(:genus_id) { Species.where(complete_data: true).first.genus.slug }
      end
    end
  end

  path '/genus/{genus_id}/species/{id}' do

    get 'Retrieve a species of a genus' do
      tags 'Genus'
      consumes 'application/json'
      produces 'application/json'
      description 'Get one species of the requested genus'
      operationId 'getSpeciesGenus'
      security [{ token: [] }, { bearerAuth: [] }]

      parameter name: :genus_id, required: true, in: :path, type: :string, description: 'The genus id or slug'
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
        let(:genus_id) { Species.where(complete_data: true).first.genus.slug }
        let(:id) { Species.where(complete_data: true).first.id }

        run_test!
      end

      response '401', 'Invalid credentials' do
        schema Schemas::Helpers.error_schema
        let(:token) { 'invalid' }
        let(:genus_id) { Species.where(complete_data: true).first.genus.slug }
        let(:id) { Species.where(complete_data: true).first.id }

        run_test!
      end

      response '404', 'Not found' do
        schema Schemas::Helpers.error_schema
        let(:token) { user.token }
        let(:genus_id) { Species.where(complete_data: true).first.genus.slug }
        let(:id) { 'does-not-exist' }
        run_test!
      end

      response_too_many_requests do
        let(:genus_id) { Species.where(complete_data: true).first.genus.slug }
        let(:id) { Species.where(complete_data: true).first.id }
      end
    end
  end

end
