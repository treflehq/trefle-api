require 'swagger_helper'

describe 'DivisionClasses API' do # rubocop:todo Metrics/BlockLength

  before :each do
    # expect(DivisionClass.count).to eq(0)
    # create(:division_class, name: 'Plantae')
  end

  after do |example|
    JsonApiHelper.save_example(example, response)
  end

  let(:user) { create(:user) }

  path '/api/v1/division_classes' do

    get 'Searches division classes' do
      tags 'DivisionClasses'
      consumes 'application/json'
      produces 'application/json'
      description 'List division classes'
      operationId 'listDivisionClasses'
      # parameter name: :id, required: true, in: :path, type: :string
      security [token: []]
      parameter name: :page, in: :query, required: false, type: :number, description: 'The page to fetch'

      response '200', 'Success' do
        schema JsonApiHelper.array_schema(
          'division_class',
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

  path '/api/v1/division_classes/{id}' do

    get 'Retrieve a division class' do
      tags 'DivisionClasses'
      consumes 'application/json'
      produces 'application/json'
      description 'Get a division class'
      operationId 'getDivisionClass'
      parameter name: :id, required: true, in: :path, type: :string, description: 'The id or the slug of the requested division class'

      security [token: []]

      response '200', 'Success' do
        schema JsonApiHelper.resource_schema(
          'division_class',
          meta: Schemas::Helpers.object_of({
            last_modified: { type: :string }
          })
        )
        let(:id) { DivisionClass.first.id }
        let(:token) { user.token }

        run_test!
      end

      response '401', 'Invalid credentials' do
        let(:token) { 'invalid' }
        let(:id) { DivisionClass.first.id }
        run_test!
      end
    end
  end
end
