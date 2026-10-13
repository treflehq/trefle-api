require 'swagger_helper'

# The OpenAPI document itself: served without a token, valid OpenAPI 3.0, and
# covering every route under /api (#221).
describe 'OpenAPI document' do

  path '/openapi.{format}' do

    get 'Retrieve the OpenAPI description of this API' do
      tags 'Root'
      produces 'application/json', 'application/yaml'
      description 'The OpenAPI 3.0 document describing every endpoint, parameter and response of this API, ' \
                  'as JSON or YAML. No token needed. Generated from the API test suite, so it matches the running version.'
      operationId 'getOpenapiDocument'
      security []

      parameter name: :format, in: :path, required: true, schema: { type: :string, enum: %w[json yaml] },
                description: 'The serialisation wanted', getter: :document_format

      response '200', 'Success' do
        schema type: :object, description: 'An OpenAPI 3.0 document', required: %w[openapi info paths], properties: {
          openapi: { type: :string, example: '3.0.1' },
          info: { type: :object },
          paths: { type: :object }
        }
        let(:document_format) { 'json' }
        run_test!
      end

      response_too_many_requests do
        let(:document_format) { 'json' }
      end
    end
  end

  describe 'GET /api/v1/openapi.yaml' do
    it 'serves the same document as YAML, cacheable and without a token' do
      get '/api/v1/openapi.yaml'

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq('application/yaml')
      expect(response.headers['Cache-Control']).to include('public')
      expect(response.headers['ETag']).to be_present
      expect(YAML.safe_load(response.body)).to eq(Openapi::Document.to_h)
    end

    it 'answers 304 to a matching If-None-Match' do
      get '/api/v1/openapi.yaml'
      get '/api/v1/openapi.yaml', headers: { 'If-None-Match' => response.headers['ETag'] }

      expect(response).to have_http_status(:not_modified)
    end
  end

  describe 'GET /api/v1/openapi.json' do
    let(:document) { JSON.parse(response.body) }

    before { get '/api/v1/openapi.json' }

    it 'is a valid OpenAPI 3.0 document' do
      parsed = Openapi3Parser.load(document)

      expect(parsed.errors.to_a).to eq([])
      expect(parsed.openapi).to start_with('3.0')
    end

    it 'is versioned with the application and points at the production server' do
      expect(document.dig('info', 'version')).to eq(TrefleAdmin::Application::VERSION)
      expect(document['servers'].map {|s| s['url'] }).to eq(['https://trefle.io/api/v1'])
    end

    it 'declares the bearer token and the token claim' do
      expect(document.dig('components', 'securitySchemes', 'bearerAuth')).to include('type' => 'http', 'scheme' => 'bearer')
      expect(document.dig('paths', '/auth/claim', 'servers', 0, 'url')).to eq('https://trefle.io/api')
      expect(document.dig('paths', '/auth/claim', 'post')).to be_present
    end

    it 'declares filter, filter_not, order and range as deepObject parameters with the controller keys' do
      parameters = document.dig('components', 'parameters')

      %w[filter_species filter_not_species order_species range_species filter_families order_families filter_genus order_genus
         filter_zones order_zones range_zones filter_corrections order_corrections].each do |name|
        expect(parameters[name]).to include('in' => 'query', 'style' => 'deepObject', 'explode' => true), name
      end
      expect(parameters.dig('filter_species', 'schema', 'properties').keys).to match_array(Api::V1::SpeciesController::FILTERABLE_FIELDS)
      expect(parameters.dig('range_species', 'schema', 'properties').keys).to match_array(Api::V1::SpeciesController::RANGEABLE_FIELDS.uniq)
      expect(parameters.dig('order_species', 'schema', 'properties').keys).to match_array(Api::V1::SpeciesController::ORDERABLE_FIELDS.uniq)
      expect(parameters.dig('filter_not_species', 'schema', 'properties').keys).to match_array(Api::V1::SpeciesController::FILTERABLE_NOT_FIELDS)
      expect(parameters.dig('filter_zones', 'schema', 'properties').keys).to match_array(Api::V1::ZonesController::FILTERABLE_FIELDS)
      expect(parameters.dig('filter_corrections', 'schema', 'properties').keys).to match_array(Api::V1::RecordCorrectionsController::FILTERABLE_FIELDS)
      expect(document.dig('paths', '/species', 'get', 'parameters')).to include('$ref' => '#/components/parameters/filter_species')
      expect(parameters.keys).to include('page', 'per_page')
    end

    it 'documents the error envelope on the 400, 401, 404 and 429 answers' do
      error_ref = { '$ref' => '#/components/schemas/error' }
      operations = document['paths'].flat_map {|_path, item| item.except('servers', 'parameters').values }

      operations.each do |op|
        expect(op.dig('responses', '429', 'content', 'application/json', 'schema')).to eq(error_ref), "#{op['operationId']} 429"
        expect(op.dig('responses', '429', 'headers').keys).to include('RateLimit-Limit', 'Retry-After'), "#{op['operationId']} 429 headers"
      end
      operations.reject {|op| op['security'] == [] }.each do |op|
        expect(op.dig('responses', '401', 'content', 'application/json', 'schema')).to eq(error_ref), "#{op['operationId']} 401"
      end
      expect(document.dig('paths', '/species/{id}', 'get', 'responses', '404', 'content', 'application/json', 'schema')).to eq(error_ref)
      expect(document.dig('paths', '/species', 'get', 'responses', '400', 'content', 'application/json', 'schema')).to eq(error_ref)
      expect(document.dig('components', 'schemas', 'error', 'required')).to eq(%w[error code message])
    end

    # Both ways: a route nobody documented, and a documented path no route serves.
    it 'covers every route under /api, and nothing else' do
      routed = Rails.application.routes.routes.filter_map do |route|
        controller = route.defaults[:controller].to_s
        next unless controller.start_with?('api/') && route.verb != 'OPTIONS'

        template = route.path.spec.to_s.sub(/\(\.:format\)\z/, '').gsub(/:(\w+)/, '{\1}')
        "#{route.verb} #{template}"
      end

      documented = document['paths'].flat_map do |template, item|
        base = URI(item.dig('servers', 0, 'url') || document['servers'].first['url']).path
        item.except('servers', 'parameters').keys.map {|verb| "#{verb.upcase} #{(base + template).chomp('/')}" }
      end

      expect(documented).to match_array(routed.uniq)
    end
  end
end
