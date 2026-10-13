require 'swagger_helper'

describe 'Families API' do

  before :each do
    # expect(Family.count).to eq(0)
    # create(:family, name: 'Plantae')
  end

  after do |example|
    JsonApiHelper.save_example(example, response)
  end

  let(:user) { create(:user) }

  path '/families' do

    get 'Searches families' do
      tags 'Families'
      consumes 'application/json'
      produces 'application/json'
      description 'List families'
      operationId 'listFamilies'
      security [{ token: [] }, { bearerAuth: [] }]
      parameters :filter_families, :order_families, :page, :per_page

      response '200', 'Success' do
        schema JsonApiHelper.array_schema(
          'family',
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

  path '/families/{id}' do

    get 'Retrieve a family' do
      tags 'Families'
      consumes 'application/json'
      produces 'application/json'
      description 'Get a family'
      operationId 'getFamily'
      parameter name: :id, required: true, in: :path, type: :string, description: 'The id or the slug of the requested family'

      security [{ token: [] }, { bearerAuth: [] }]

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
        schema Schemas::Helpers.error_schema
        let(:token) { 'invalid' }
        let(:id) { Family.first.id }
        run_test!
      end

      response '404', 'Not found' do
        schema Schemas::Helpers.error_schema
        let(:token) { user.token }
        let(:id) { 'does-not-exist' }
        run_test!
      end

      response_too_many_requests do
        let(:id) { Family.first.id }
      end
    end
  end

  path '/families/{family_id}/genus' do

    get 'List genus of a family' do
      tags 'Families'
      consumes 'application/json'
      produces 'application/json'
      description 'List the genus of the requested family'
      operationId 'listGenusFamily'
      security [{ token: [] }, { bearerAuth: [] }]

      parameter name: :family_id, required: true, in: :path, type: :string, description: 'The family id or slug'
      parameters :filter_genus, :order_genus, :page, :per_page

      response '200', 'Success' do
        schema JsonApiHelper.array_schema(
          'genus',
          links: Schemas::Helpers.pagination_links,
          meta: Schemas::Helpers.pagination_meta
        )
        let(:token) { user.token }
        let(:family_id) { Genus.first.family.slug }

        run_test!
      end

      response '401', 'Invalid credentials' do
        schema Schemas::Helpers.error_schema
        let(:token) { 'invalid' }
        let(:family_id) { Genus.first.family.slug }

        run_test!
      end

      response '400', 'Unknown filter, filter_not, order or range key, or invalid filter value' do
        schema Schemas::Helpers.error_schema
        let(:token) { user.token }
        let(:family_id) { Genus.first.family.slug }
        let(:filter) { { not_a_field: 'x' } }
        run_test!
      end

      response '404', 'Not found' do
        schema Schemas::Helpers.error_schema
        let(:token) { user.token }
        let(:family_id) { 'does-not-exist' }
        run_test!
      end

      response_too_many_requests do
        let(:family_id) { Genus.first.family.slug }
      end
    end
  end

  path '/families/{family_id}/genus/{id}' do

    get 'Retrieve a genus of a family' do
      tags 'Families'
      consumes 'application/json'
      produces 'application/json'
      description 'Get one genus of the requested family'
      operationId 'getGenusFamily'
      security [{ token: [] }, { bearerAuth: [] }]

      parameter name: :family_id, required: true, in: :path, type: :string, description: 'The family id or slug'
      parameter name: :id, required: true, in: :path, type: :string, description: 'The id or the slug of the requested record'

      response '200', 'Success' do
        schema JsonApiHelper.resource_schema(
          'genus',
          meta: Schemas::Helpers.object_of({
            last_modified: { type: :string }
          })
        )
        let(:token) { user.token }
        let(:family_id) { Genus.first.family.slug }
        let(:id) { Genus.first.id }

        run_test!
      end

      response '401', 'Invalid credentials' do
        schema Schemas::Helpers.error_schema
        let(:token) { 'invalid' }
        let(:family_id) { Genus.first.family.slug }
        let(:id) { Genus.first.id }

        run_test!
      end

      response '404', 'Not found' do
        schema Schemas::Helpers.error_schema
        let(:token) { user.token }
        let(:family_id) { Genus.first.family.slug }
        let(:id) { 'does-not-exist' }
        run_test!
      end

      response_too_many_requests do
        let(:family_id) { Genus.first.family.slug }
        let(:id) { Genus.first.id }
      end
    end
  end

end
