require 'rails_helper'
require 'zlib'

# Rack::Deflater (config/application.rb): API responses used to be sent
# uncompressed whatever the client's Accept-Encoding.
RSpec.describe 'Response compression', type: :request do
  let(:user) { create(:user) }
  let!(:species) { create(:species) }

  def gunzip(body)
    Zlib::GzipReader.new(StringIO.new(body)).read
  end

  describe 'an API JSON response' do
    it 'is gzipped when the client accepts gzip' do
      get '/api/v1/species', params: { token: user.token }, headers: { 'Accept-Encoding' => 'gzip' }

      expect(response).to have_http_status(:ok)
      expect(response.headers['Content-Encoding']).to eq('gzip')
      expect(response.headers['Vary']).to include('Accept-Encoding')
      expect(JSON.parse(gunzip(response.body))['data']).to be_an(Array)
    end

    it 'is sent as is when the client does not ask for compression' do
      get '/api/v1/species', params: { token: user.token }

      expect(response.headers['Content-Encoding']).to be_nil
      expect(response.parsed_body['data']).to be_an(Array)
    end

    it 'keeps its rate-limit and CORS headers when gzipped' do
      get '/api/v1/species', params: { token: user.token },
                             headers: { 'Accept-Encoding' => 'gzip', 'Origin' => 'https://example.com' }

      expect(response.headers['Content-Encoding']).to eq('gzip')
      expect(response.headers['Access-Control-Allow-Origin']).to eq('*')
      expect(response.headers['Access-Control-Expose-Headers']).to include('RateLimit-Limit')
    end
  end

  it 'gzips the OpenAPI document' do
    get '/api/v1/openapi.json', headers: { 'Accept-Encoding' => 'gzip' }

    expect(response.headers['Content-Encoding']).to eq('gzip')
    expect(JSON.parse(gunzip(response.body))).to include('openapi')
  end

  describe 'conditional requests' do
    let(:path) { "/api/v1/species/#{species.slug}" }

    it 'gives the same ETag to the gzipped and the plain response, and answers 304 to it' do
      get path, params: { token: user.token }, headers: { 'Accept-Encoding' => 'gzip' }
      gzipped_etag = response.headers['ETag']
      expect(response.headers['Content-Encoding']).to eq('gzip')

      get path, params: { token: user.token }
      expect(response.headers['ETag']).to eq(gzipped_etag)

      get path, params: { token: user.token }, headers: { 'Accept-Encoding' => 'gzip', 'If-None-Match' => gzipped_etag }
      expect(response).to have_http_status(:not_modified)
      expect(response.headers['Content-Encoding']).to be_nil
      expect(response.body).to be_empty
    end
  end

  describe 'its configuration' do
    let(:options) { Rails.application.middleware.find {|middleware| middleware.klass == Rack::Deflater }.args.first }

    it 'sits outside Rack::ETag, inside Rack::ConditionalGet' do
      klasses = Rails.application.middleware.map(&:klass)

      expect(klasses.index(Rack::Deflater)).to be < klasses.index(Rack::ETag)
      expect(klasses.index(Rack::Deflater)).to be > klasses.index(Rack::ConditionalGet)
    end

    it 'compresses text formats only' do
      expect(options[:include]).to include('application/json', 'application/yaml', 'text/html', 'text/plain')
      expect(options[:include]).not_to include('image/png', 'image/webp', 'font/woff2')
    end

    it 'leaves a body known to be under 1 KB alone' do
      condition = options[:if]

      expect(condition.call({}, 200, { 'content-length' => '200' }, [])).to be(false)
      expect(condition.call({}, 200, { 'content-length' => '4096' }, [])).to be(true)
      expect(condition.call({}, 200, {}, [])).to be(true)
    end
  end
end
