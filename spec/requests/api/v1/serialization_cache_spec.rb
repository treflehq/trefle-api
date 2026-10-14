require 'rails_helper'

# The serialized payloads are cached (memcached in production) under a key
# that also serves as the detail's ETag. The key used to depend on the record
# only, so a release that changed a payload went on serving the previous
# release's version of every cached record (2.9.7: rosa-canina still carried
# its 1,083 synonyms). The key now carries the release.
RSpec.describe 'Serialization cache', type: :request do
  let(:user) { create(:user) }
  let!(:species) { create(:species, common_name: 'Old name') }
  let(:memory_store) { ActiveSupport::Cache::MemoryStore.new }

  before do
    allow(Rails).to receive(:cache).and_return(memory_store)
  end

  # Changes what the serializer would output without moving the record's
  # cache_version, the way a code change does.
  def change_payload_behind_the_cache!
    species.update_column(:common_name, 'New name')
  end

  describe 'the key' do
    # The key reads the request parameters that shape the payload.
    let(:query) { {} }
    let(:controller) do
      Api::V1::SpeciesController.new.tap do |controller|
        controller.request = ActionDispatch::TestRequest.create
        controller.params = query
      end
    end

    it 'carries the application version and the image revision' do
      stub_const('TrefleAdmin::Application::VERSION', '9.8.7')
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('APP_REVISION').and_return('v9.8.7')

      key = controller.serialization_cache_key(SpeciesSerializer, species)

      expect(key).to start_with('9.8.7+v9.8.7/SpeciesSerializer/')
      expect(key).to end_with("#{species.cache_key}-#{species.cache_version}")
    end

    it 'changes with the version' do
      before_release = controller.serialization_cache_key(SpeciesLightSerializer, species, scope: 'collection')
      stub_const('TrefleAdmin::Application::VERSION', '99.0.0')

      expect(controller.serialization_cache_key(SpeciesLightSerializer, species, scope: 'collection')).not_to eq(before_release)
    end

    it 'carries the variant of the payload the request parameters shape, none by default' do
      default_key = controller.serialization_cache_key(SpeciesSerializer, species)
      allow(controller).to receive(:serialization_variant_parts).and_return({ a: 'x', b: nil, c: 'y' })

      key = controller.serialization_cache_key(SpeciesSerializer, species)

      expect(key).to include('/SpeciesSerializer/a=x&c=y/')
      expect(default_key).not_to include('=')
    end
  end

  describe 'the detail' do
    let(:path) { "/api/v1/species/#{species.slug}" }

    def get_detail(headers = {})
      get path, params: { token: user.token }, headers: headers
    end

    it 'serves the cached payload within a release, a fresh one after a release' do
      get_detail
      expect(response.parsed_body.dig('data', 'common_name')).to eq('Old name')

      change_payload_behind_the_cache!
      get_detail
      expect(response.parsed_body.dig('data', 'common_name')).to eq('Old name')

      stub_const('TrefleAdmin::Application::VERSION', '99.0.0')
      get_detail
      expect(response.parsed_body.dig('data', 'common_name')).to eq('New name')
    end

    it 'answers 304 to its ETag within a release, 200 with a new ETag after a release' do
      get_detail
      etag = response.headers['ETag']
      last_modified = response.headers['Last-Modified']
      expect(etag).to be_present

      get_detail('If-None-Match' => etag, 'If-Modified-Since' => last_modified)
      expect(response).to have_http_status(:not_modified)

      stub_const('TrefleAdmin::Application::VERSION', '99.0.0')
      get_detail('If-None-Match' => etag, 'If-Modified-Since' => last_modified)
      expect(response).to have_http_status(:ok)
      expect(response.headers['ETag']).not_to eq(etag)
    end

    it 'does not date Last-Modified before the running code' do
      species.update_column(:updated_at, 1.year.ago)

      get_detail

      expect(Time.httpdate(response.headers['Last-Modified'])).to be >= CollectionRenderers::BOOTED_AT.change(usec: 0)
    end
  end

  describe 'the collection rows' do
    def listed_common_name
      get '/api/v1/species', params: { token: user.token, filter: { scientific_name: species.scientific_name } }
      response.parsed_body['data'].find {|row| row['id'] == species.id }&.dig('common_name')
    end

    it 'serves cached rows within a release, fresh ones after a release' do
      expect(listed_common_name).to eq('Old name')

      change_payload_behind_the_cache!
      expect(listed_common_name).to eq('Old name')

      stub_const('TrefleAdmin::Application::VERSION', '99.0.0')
      expect(listed_common_name).to eq('New name')
    end
  end
end
