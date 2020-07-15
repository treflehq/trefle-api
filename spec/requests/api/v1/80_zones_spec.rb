require 'swagger_helper'

describe 'Distributions API' do # rubocop:todo Metrics/BlockLength

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
      description <<-DESC
      List distributions zones. Zones are following the WGSRPD convention.
      WGSRPD provides an agreed system of geographical units at approximately "country" level and upwards for use in recording plant distributions. It allows adopting organizations to compare and exchange data with each other without loss of information due to incompatible geographical boundaries.
      [Read more on the TDWG website](https://www.tdwg.org/standards/wgsrpd/).
      DESC

      operationId 'listDistributions'
      # parameter name: :id, required: true, in: :path, type: :string
      security [token: []]
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

      security [token: []]

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
end
