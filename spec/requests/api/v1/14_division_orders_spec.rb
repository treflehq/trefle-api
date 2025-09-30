require 'swagger_helper'

describe 'DivisionOrders API' do # rubocop:todo Metrics/BlockLength

  before :each do
    # expect(DivisionOrder.count).to eq(0)
    # create(:division_order, name: 'Plantae')
  end

  after do |example|
    JsonApiHelper.save_example(example, response)
  end

  let(:user) { create(:user) }

  path '/api/v1/division_orders' do

    get 'Searches division orders' do
      tags 'DivisionOrders'
      consumes 'application/json'
      produces 'application/json'
      description 'List division orders'
      operationId 'listDivisionOrders'
      # parameter name: :id, required: true, in: :path, type: :string
      security [token: []]
      parameter name: :page, in: :query, required: false, type: :number, description: 'The page to fetch'

      response '200', 'Success' do
        schema JsonApiHelper.array_schema(
          'division_order',
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

  path '/api/v1/division_orders/{id}' do

    get 'Retrieve a division order' do
      tags 'DivisionOrders'
      consumes 'application/json'
      produces 'application/json'
      description 'Get a division order'
      operationId 'getDivisionOrder'
      parameter name: :id, required: true, in: :path, type: :string, description: 'The id or the slug of the requested division order'

      security [token: []]

      response '200', 'Success' do
        schema JsonApiHelper.resource_schema(
          'division_order',
          meta: Schemas::Helpers.object_of({
            last_modified: { type: :string }
          })
        )
        let(:id) { DivisionOrder.first.id }
        let(:token) { user.token }

        run_test!
      end

      response '401', 'Invalid credentials' do
        let(:token) { 'invalid' }
        let(:id) { DivisionOrder.first.id }
        run_test!
      end
    end
  end
end
