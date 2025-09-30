require 'swagger_helper'

describe 'Divisions API' do # rubocop:todo Metrics/BlockLength

  before :each do
    # expect(Division.count).to eq(0)
    # create(:division, name: 'Plantae')
  end

  after do |example|
    JsonApiHelper.save_example(example, response)
  end

  let(:user) { create(:user) }

  path '/api/v1/divisions' do

    get 'Searches divisions' do
      tags 'Divisions'
      consumes 'application/json'
      produces 'application/json'
      description 'List divisions'
      operationId 'listDivisions'
      # parameter name: :id, required: true, in: :path, type: :string
      security [token: []]
      parameter name: :page, in: :query, required: false, type: :number, description: 'The page to fetch'

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
        let(:token) { 'invalid' }
        run_test!
      end
    end
  end

  path '/api/v1/divisions/{id}' do

    get 'Retrieve a division' do
      tags 'Divisions'
      consumes 'application/json'
      produces 'application/json'
      description 'Get a division'
      operationId 'getDivision'
      parameter name: :id, required: true, in: :path, type: :string, description: 'The id or the slug of the requested division'

      security [token: []]

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
        let(:token) { 'invalid' }
        let(:id) { Division.first.id }
        run_test!
      end
    end
  end
end
