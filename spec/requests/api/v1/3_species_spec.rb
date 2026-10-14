require 'swagger_helper'

describe 'Species API' do

  before :each do
    # expect(Species.count).to eq(0)
    # create(:species, name: 'Speciesae')
  end

  after do |example|
    JsonApiHelper.save_example(example, response)
  end

  let(:user) { create(:user) }

  path '/species' do

    get 'List species' do
      tags 'Species'
      consumes 'application/json'
      produces 'application/json'
      description 'List species'
      operationId 'listSpecies'
      security [{ token: [] }, { bearerAuth: [] }]

      parameters :filter_species, :filter_not_species, :order_species, :range_species, :page, :per_page, :lang

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
                      "inverted or non-numeric range, unknown lang, or page beyond #{WithCachedCount::MAX_PAGE_DEPTH}" do
        schema Schemas::Helpers.error_schema
        let(:token) { user.token }
        let(:filter) { { not_a_field: 'x' } }
        run_test!
      end

      response_too_many_requests
    end
  end

  path '/species/{id}' do

    get 'Retrieve a species' do
      tags 'Species'
      consumes 'application/json'
      produces 'application/json'
      description 'Get a species'
      operationId 'getSpecies'
      parameters :lang
      parameter name: :id, required: true, in: :path, type: :string, description: 'The id or the slug of the requested species'

      security [{ token: [] }, { bearerAuth: [] }]

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

  path '/species/search' do

    get 'Search for a species' do
      tags 'Species'
      consumes 'application/json'
      produces 'application/json'
      description 'Search for a species with the given scientific name, common name, synonym name etc.'
      operationId 'searchSpecies'
      parameters :q, :page, :per_page, :filter_species, :filter_not_species, :order_species, :range_species, :lang

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

  path '/species/{id}/report' do

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

      tags 'Species'
      consumes 'application/json'
      produces 'application/json'
      description 'A short API call to report an error regarding a species entry'
      operationId 'reportSpecies'
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

  path '/species/{id}/facts' do

    get 'List the provenance facts of a species' do
      tags 'Species'
      produces 'application/json'
      description 'Every sourced claim about this species\' trait values, including superseded and rejected ones. ' \
                  'The species trait columns are a projection of the strongest active fact per attribute; this endpoint is the trail behind them.'
      operationId 'listSpeciesFacts'
      security [{ token: [] }, { bearerAuth: [] }]

      parameter name: :id, required: true, in: :path, type: :string, description: 'The id or the slug of the requested species'

      response '200', 'Success' do
        schema JsonApiHelper.array_schema(
          'species_fact',
          meta: Schemas::Helpers.object_of({
            total: { type: :integer }
          })
        )
        let(:token) { user.token }
        let(:id) { Species.where(complete_data: true).first.id }
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

  path '/species/{species_id}/synonyms' do

    get 'List the synonyms of a species' do
      tags 'Species'
      produces 'application/json'
      description 'The paginated list of the species synonyms, ordered by name. Includes the synonyms attached to the species autonyms ' \
                  '(the typical subspecies or variety, e.g. "Quercus robur subsp. robur", where WCVP records the synonyms of the type); ' \
                  '`attached_to` says which record each one hangs on. ' \
                  "The species detail only embeds the first #{SpeciesSerializer::SYNONYMS_LIMIT} of them."
      operationId 'listSpeciesSynonyms'
      security [{ token: [] }, { bearerAuth: [] }]

      parameter name: :species_id, required: true, in: :path, type: :string, description: 'The id or the slug of the species'
      parameters :page, :per_page

      response '200', 'Success' do
        schema JsonApiHelper.array_schema(
          'synonym',
          links: Schemas::Helpers.pagination_links,
          meta: Schemas::Helpers.pagination_meta(
            species: Schemas::Helpers.object_of({
              id: { type: :integer },
              slug: { type: :string },
              scientific_name: { type: :string }
            }, extras: { description: 'The species the synonyms belong to' })
          )
        )
        let(:token) { user.token }
        let(:species_id) { 'abies-alba' }
        run_test!
      end

      response '401', 'Invalid credentials' do
        schema Schemas::Helpers.error_schema
        let(:token) { 'invalid' }
        let(:species_id) { 'abies-alba' }
        run_test!
      end

      response '400', 'Invalid page size' do
        schema Schemas::Helpers.error_schema
        let(:token) { user.token }
        let(:species_id) { 'abies-alba' }
        let(:per_page) { 0 }
        run_test!
      end

      response '404', 'Not found' do
        schema Schemas::Helpers.error_schema
        let(:token) { user.token }
        let(:species_id) { 'does-not-exist' }
        run_test!
      end

      response_too_many_requests do
        let(:species_id) { 'abies-alba' }
      end
    end
  end

  path '/species/{species_id}/corrections' do

    get 'List the corrections submitted on a species' do
      tags 'Species'
      produces 'application/json'
      description 'The community corrections submitted on this species, whatever their status'
      operationId 'listSpeciesCorrections'
      security [{ token: [] }, { bearerAuth: [] }]

      parameter name: :species_id, required: true, in: :path, type: :string, description: 'The id or the slug of the species'
      parameters :filter_corrections, :order_corrections, :page, :per_page

      response '200', 'Success' do
        schema JsonApiHelper.array_schema(
          'correction',
          links: Schemas::Helpers.pagination_links,
          meta: Schemas::Helpers.pagination_meta
        )
        let(:token) { user.token }
        let(:species_id) { Species.where(complete_data: true).first.id }
        run_test!
      end

      response '401', 'Invalid credentials' do
        schema Schemas::Helpers.error_schema
        let(:token) { 'invalid' }
        let(:species_id) { Species.where(complete_data: true).first.id }
        run_test!
      end

      response '400', 'Unknown filter, filter_not, order or range key, or invalid filter value' do
        schema Schemas::Helpers.error_schema
        let(:token) { user.token }
        let(:species_id) { Species.where(complete_data: true).first.id }
        let(:filter) { { not_a_field: 'x' } }
        run_test!
      end

      response '404', 'Not found' do
        schema Schemas::Helpers.error_schema
        let(:token) { user.token }
        let(:species_id) { 'does-not-exist' }
        run_test!
      end

      response_too_many_requests do
        let(:species_id) { Species.where(complete_data: true).first.id }
      end
    end
  end
end
