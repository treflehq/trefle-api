require 'swagger_helper'

describe 'Corrections API' do # rubocop:todo Metrics/BlockLength

  before :each do
    # expect(RecordCorrection.count).to eq(0)
    record = Species.where.not(maximum_height_cm: nil).first
    create(
      :record_correction,
      record: record,
      notes: 'The height is wrong, it\'s way smaller',
      correction_json: {
        scientific_name: record.scientific_name,
        maximum_height_value: record.maximum_height_cm / 2,
        maximum_height_unit: 'cm'
      }.to_json
    )
    create(
      :record_correction,
      notes: 'Is the author okay ?'
    )
    # create(
    #   :record_correction,
    #   change_type: :addition,
    #   correction_json: {
    #     scientific_name: "Abies maximus subsp. totalus",
    #     author: 'Aubin',
    #     year: '2020',
    #     observations: 'This tree doesn\'t exists'
    #   }.to_json,
    #   change_status: :rejected,
    #   notes: 'Here is a new species !',
    # )
  end

  after do |example|
    JsonApiHelper.save_example(example, response)
  end

  let(:user) { create(:user) }

  path '/api/v1/corrections' do

    get 'Searches corrections' do
      tags 'Corrections'
      consumes 'application/json'
      produces 'application/json'
      description 'List corrections'
      operationId 'listCorrections'
      security [token: []]

      response '200', 'Success' do
        schema JsonApiHelper.array_schema(
          'correction',
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

  path '/api/v1/corrections/{id}' do

    get 'Retrieve a correction' do
      tags 'Corrections'
      consumes 'application/json'
      produces 'application/json'
      description 'Get a correction'
      operationId 'getCorrection'
      parameter name: :id, required: true, in: :path, type: :string, description: 'The id of the requested correction'

      security [token: []]

      response '200', 'Success' do
        schema JsonApiHelper.resource_schema(
          'correction',
          meta: Schemas::Helpers.object_of({
            last_modified: { type: :string }
          })
        )
        let(:id) { RecordCorrection.first.id }
        let(:token) { user.token }

        run_test!
      end

      response '401', 'Invalid credentials' do
        let(:token) { 'invalid' }
        let(:id) { RecordCorrection.first.id }
        run_test!
      end
    end
  end

  path '/api/v1/corrections/species/{record_id}' do # rubocop:todo Metrics/BlockLength

    post 'Submit a correction' do # rubocop:todo Metrics/BlockLength

      # correctionSchema = {
      #   type: :object,
      #   properties: {
      #     correction: {
      #       type: 'object',
      #       example: 'The flower color is red',
      #       description: 'An optional note about the incorrect data'
      #     }
      #   }
      # }

      tags 'Corrections'
      consumes 'application/json'
      produces 'application/json'
      description 'Submit a new correction for the given species, that will be reviewed and merged into the database. See [Complete our data](/docs/advanced/complete-data) to get started.'
      operationId 'createCorrection'
      parameter name: :correction, required: false, in: :body, schema: Schemas::Helpers.schema_href(schema: 'request_body_correction')
      parameter name: :record_id, required: true, in: :path, type: :string, description: 'The id or the slug of the requested correction'

      security [token: []]

      response '201', 'Success' do
        schema JsonApiHelper.resource_schema(
          'correction',
          meta: Schemas::Helpers.object_of({
            last_modified: { type: :string }
          })
        )
        let(:record_id) { Species.friendly.find('abies-alba').id }
        let(:correction) do
          {
            notes: 'This tree can grows up to 68 meters',
            source_type: :external,
            source_reference: 'https://conifersociety.org/conifers/abies-alba/',
            correction: {
              maximum_height_value: 6800,
              maximum_height_unit: 'cm'
            }
          }
        end
        let(:token) { user.token }

        run_test!
      end

      response '422', 'Invalid parameters' do
        let(:record_id) { Species.where.not(maximum_height_cm: nil).first.id }
        let(:correction) { { hello: :world } }
        let(:token) { user.token }

        run_test!
      end

      response '401', 'Invalid credentials' do
        let(:token) { 'invalid' }
        let(:record_id) { Species.where.not(maximum_height_cm: nil).first.id }
        run_test!
      end
    end
  end
end
