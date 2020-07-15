require 'swagger_helper'

describe 'Kingdoms API' do # rubocop:todo Metrics/BlockLength

  before :each do
    # expect(Kingdom.count).to eq(0)
    # create(:kingdom, name: 'Plantae')
  end

  after do |example|
    JsonApiHelper.save_example(example, response)
  end

  let(:user) { create(:user) }

  path '/api/v1/kingdoms' do

    get 'Searches kingdoms' do
      tags 'Kingdoms'
      consumes 'application/json'
      produces 'application/json'
      description 'List kingdoms'
      operationId 'listKingdoms'
      # parameter name: :id, required: true, in: :path, type: :string
      security [token: []]
      parameter name: :page, in: :query, required: false, type: :number, description: 'The page to fetch'

      response '200', 'Success' do
        schema JsonApiHelper.array_schema(
          'kingdom',
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

  path '/api/v1/kingdoms/{id}' do

    get 'Retrieve a kingdom' do
      tags 'Kingdoms'
      consumes 'application/json'
      produces 'application/json'
      description 'Get a kingdom'
      operationId 'getKingdom'
      parameter name: :id, required: true, in: :path, type: :string, description: 'The id or the slug of the requested kingdom'

      security [token: []]

      response '200', 'Success' do
        schema JsonApiHelper.resource_schema(
          'kingdom',
          meta: Schemas::Helpers.object_of({
            last_modified: { type: :string }
          })
        )
        let(:id) { Kingdom.first.id }
        let(:token) { user.token }

        run_test!
      end

      response '401', 'Invalid credentials' do
        let(:token) { 'invalid' }
        let(:id) { Kingdom.first.id }
        run_test!
      end
    end
  end
end
