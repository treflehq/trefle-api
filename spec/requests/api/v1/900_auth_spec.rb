require 'swagger_helper'

describe 'Auth API' do # rubocop:todo Metrics/BlockLength

  before :each do
    # expect(Zone.count).to eq(0)
    # create(:zone, name: 'Plantae')
  end

  after do |example|
    JsonApiHelper.save_example(example, response)
  end

  claim_schema = Schemas::Helpers.object_of({
    origin: { type: :string, example: 'https://example.com', description: 'The website url the API requests will come from' },
    ip: { type: :string, nullable: true, example: '12.23.34.45', description: 'The client IP' }
  }, extras: { required: %w[origin] })

  let(:user) { create(:user) }

  path '/api/auth/claim' do

    post 'Request a client-side token' do
      tags 'Auth'
      consumes 'application/json'
      produces 'application/json'
      description <<~DESC
        If you need to perform client-side requests, you will have to request a client-side token from you backend, and get a JWT token from this API call in return. This token will be usable on the client side. This call need your secret access token, the url of the website the client side requests will come from and optionally the client IP address.
      DESC

      operationId 'claimClientSideToken'
      # parameter name: :id, required: true, in: :path, type: :string
      security [token: []]
      parameter name: :claim_params, required: true, in: :body, schema: claim_schema

      response '200', 'Success' do
        schema Schemas::Helpers.object_of({
          expiration: { type: :string, example: '07-13-2020 13:41', description: 'The expiration time of the token. After this time, you\'ll have to request a token again' },
          token: { type: :string, example: 'eyJhbGciOiJIUzI1NaJ9.eyJ1c2VyX2lkIjoxMDYsIe9yaWdpbiI6Imh0dHA6Ly9wb2NhbGhvc3Q6MzIzMyIsImlwIjoiOjoxIiwiZXhwIjoxNTk0NjQwNTEzfQ.TyqKyKxwsnn7TZsLAfS8OTmTUPk87CSXlk6a2wQU9co', description: 'The client-side access token, that you\'ll use instead of your access token in the `token` parameter' }
        })
        let(:token) { user.token }
        let(:claim_params) do
          {
            origin: 'http://localhost:1234',
            ip: '::1'
          }
        end
        run_test!
      end

      response '401', 'Invalid credentials' do
        let(:token) { 'invalid' }
        let(:claim_params) do
          {
            ip: '::1'
          }
        end

        run_test!
      end

      response '422', 'Missing parameters' do
        let(:token) { user.token }
        let(:claim_params) do
          {
            ip: '::1'
          }
        end

        run_test!
      end
    end
  end

end
