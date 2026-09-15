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

  path '/api/v1/families' do

    get 'Searches families' do
      tags 'Families'
      consumes 'application/json'
      produces 'application/json'
      description 'List families'
      operationId 'listFamilies'
      # parameter name: :id, required: true, in: :path, type: :string
      security [{ token: [] }, { bearerAuth: [] }]
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
        let(:token) { 'invalid' }
        let(:id) { Family.first.id }
        run_test!
      end
    end
  end

  path '/api/v1/families/{family_id}/genus' do

    get 'List genus of a family' do
      tags 'Families'
      consumes 'application/json'
      produces 'application/json'
      description 'List the genus of the requested family'
      operationId 'listGenusFamily'
      security [{ token: [] }, { bearerAuth: [] }]

      parameter name: :family_id, required: true, in: :path, type: :string, description: 'The family id or slug'
      parameter name: :filter, in: :query, required: false, description: 'Filter on values', schema: Schemas::Helpers.schema_href(schema: 'filters_genus')
      parameter name: :order, in: :query, required: false, description: 'Sort on values', schema: Schemas::Helpers.schema_href(schema: 'sorts_genus')
      parameter name: :page, in: :query, required: false, type: :number, description: 'The page to fetch'

      response '200', 'Success' do
        schema JsonApiHelper.array_schema(
          'genus',
          links: Schemas::Helpers.pagination_links,
          meta: Schemas::Helpers.object_of({
            total: { type: :integer }
          })
        )
        let(:token) { user.token }
        let(:family_id) { Genus.first.family.slug }

        run_test!
      end

      response '401', 'Invalid credentials' do
        let(:token) { 'invalid' }
        let(:family_id) { Genus.first.family.slug }

        run_test!
      end
    end
  end

  path '/api/v1/families/{family_id}/genus/{id}' do

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
        let(:token) { 'invalid' }
        let(:family_id) { Genus.first.family.slug }
        let(:id) { Genus.first.id }

        run_test!
      end
    end
  end

end
