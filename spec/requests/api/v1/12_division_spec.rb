require 'swagger_helper'

describe 'Divisions API' do

  before :each do
    # expect(Division.count).to eq(0)
    # create(:division, name: 'Plantae')
  end

  after do |example|
    JsonApiHelper.save_example(example, response)
  end

  let(:user) { create(:user) }

  path '/divisions' do

    get 'Searches divisions' do
      tags 'Divisions'
      consumes 'application/json'
      produces 'application/json'
      description 'List divisions'
      operationId 'listDivisions'
      security [{ token: [] }, { bearerAuth: [] }]
      parameters :page, :per_page

      response '200', 'Success' do
        schema JsonApiHelper.array_schema(
          'division',
          links: Schemas::Helpers.pagination_links,
          meta: Schemas::Helpers.object_of({
            total: { type: :integer }
          })
        )
        let(:token) { user.token }
        run_test!
      end

      response '401', 'Invalid credentials' do
        schema Schemas::Helpers.error_schema
        let(:token) { 'invalid' }
        run_test!
      end

      response_too_many_requests
    end
  end

  path '/divisions/{id}' do

    get 'Retrieve a division' do
      tags 'Divisions'
      consumes 'application/json'
      produces 'application/json'
      description 'Get a division'
      operationId 'getDivision'
      parameter name: :id, required: true, in: :path, type: :string, description: 'The id or the slug of the requested division'

      security [{ token: [] }, { bearerAuth: [] }]

      response '200', 'Success' do
        schema JsonApiHelper.resource_schema(
          'division',
          meta: Schemas::Helpers.object_of({
            last_modified: { type: :string }
          })
        )
        let(:id) { Division.first.id }
        let(:token) { user.token }

        run_test!
      end

      response '401', 'Invalid credentials' do
        schema Schemas::Helpers.error_schema
        let(:token) { 'invalid' }
        let(:id) { Division.first.id }
        run_test!
      end

      response '404', 'Not found' do
        schema Schemas::Helpers.error_schema
        let(:token) { user.token }
        let(:id) { 'does-not-exist' }
        run_test!
      end

      response_too_many_requests do
        let(:id) { Division.first.id }
      end
    end
  end
end
