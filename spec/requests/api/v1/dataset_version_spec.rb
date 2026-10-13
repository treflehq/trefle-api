require 'rails_helper'

# The data version (DatasetVersion) on every API answer: the root, the
# meta of lists and details, the X-Trefle-Data-Version header, and the public
# changelog.
RSpec.describe 'Dataset version', type: :request do
  let(:user) { create(:user) }
  let!(:kingdom) { Kingdom.first || create(:kingdom) }
  let!(:run) do
    DataRun.create!(
      runnable: 'Crawlers::SecretWorker', kind: 'import', status: :completed,
      arguments: { 'path' => '/Users/someone/datasets/try.bin' },
      report: { 'promoted' => 12 }, host: 'laptop.local', revision: 'abc123',
      started_at: Time.utc(2026, 10, 13, 6, 0), finished_at: Time.utc(2026, 10, 13, 6, 40),
      impact: { 'species_facts' => { 'before' => 1, 'after' => 13, 'delta' => 12 },
                'species' => { 'before' => 5, 'after' => 5, 'delta' => 0 } }
    )
  end

  before { DatasetVersion.reset! }
  after { DatasetVersion.reset! }

  describe 'GET /api/v1' do
    it 'states the version, its release date, the licence and where to cite' do
      get '/api/v1/'

      body = response.parsed_body
      expect(body['dataset_version']).to eq('2026.10.13')
      expect(body['dataset']).to include(
        'version' => '2026.10.13',
        'licence' => 'CC-BY-4.0',
        'citation_url' => end_with('/citation'),
        'changelog_url' => end_with('/api/v1/changelog')
      )
      expect(Time.zone.parse(body['dataset']['released_at'])).to eq(run.finished_at)
      expect(response.headers['X-Trefle-Data-Version']).to eq('2026.10.13')
    end

    it 'answers null, and no header, before any data run was recorded' do
      DataRun.delete_all
      DatasetVersion.reset!

      get '/api/v1/'

      expect(response.parsed_body['dataset_version']).to be_nil
      expect(response.headers).not_to have_key('X-Trefle-Data-Version')
    end
  end

  describe 'authenticated endpoints' do
    it 'carries the version in the meta and the header of a list' do
      get '/api/v1/kingdoms', params: { token: user.token }

      expect(response.parsed_body.dig('meta', 'dataset_version')).to eq('2026.10.13')
      expect(response.headers['X-Trefle-Data-Version']).to eq('2026.10.13')
    end

    it 'carries the version in the meta of a detail' do
      get "/api/v1/kingdoms/#{kingdom.id}", params: { token: user.token }

      expect(response.parsed_body.dig('meta', 'dataset_version')).to eq('2026.10.13')
    end

    it 'changes the ETag of a detail when a new data version is released' do
      get "/api/v1/kingdoms/#{kingdom.id}", params: { token: user.token }
      etag = response.headers['ETag']

      DataRun.create!(runnable: 'Spec::Run', kind: 'migration', status: :completed,
                      started_at: Time.utc(2026, 10, 14, 8, 0), finished_at: Time.utc(2026, 10, 14, 8, 5))
      DatasetVersion.reset!

      get "/api/v1/kingdoms/#{kingdom.id}", params: { token: user.token }, headers: { 'If-None-Match' => etag }
      expect(response).to have_http_status(:ok)
      expect(response.headers['ETag']).not_to eq(etag)
      expect(response.parsed_body.dig('meta', 'dataset_version')).to eq('2026.10.14')
    end

    it 'says which version answered, even on a 401' do
      get '/api/v1/kingdoms', params: { token: 'invalid' }

      expect(response).to have_http_status(:unauthorized)
      expect(response.headers['X-Trefle-Data-Version']).to eq('2026.10.13')
    end

    it 'exposes the header to browser clients' do
      get '/api/v1/kingdoms', params: { token: user.token }, headers: { 'Origin' => 'https://example.org' }

      expect(response.headers['Access-Control-Expose-Headers']).to include('X-Trefle-Data-Version')
    end
  end

  describe 'GET /api/v1/changelog' do
    it 'lists the versions without a token, newest first' do
      DataRun.create!(runnable: 'Spec::Run', kind: 'migration', status: :failed,
                      started_at: Time.utc(2026, 10, 13, 7, 0), finished_at: Time.utc(2026, 10, 13, 7, 1))
      DataRun.create!(runnable: 'Spec::Run', kind: 'migration', dry_run: true,
                      started_at: Time.utc(2026, 10, 13, 8, 0), finished_at: Time.utc(2026, 10, 13, 8, 1))

      get '/api/v1/changelog'

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body['data'].pluck('version')).to eq(%w[2026.10.13.2 2026.10.13])
      expect(body['data'].pluck('status')).to eq(%w[failed completed])
      expect(body['meta']).to eq('total' => 2, 'dataset_version' => '2026.10.13.2')
    end

    it 'publishes only the safe fields of a run: no class, arguments, report, host or revision' do
      get '/api/v1/changelog'

      entry = response.parsed_body['data'].first
      expect(entry.keys).to match_array(%w[version kind status started_at finished_at changes])
      expect(entry['changes']).to eq('species_facts' => 12)
      expect(response.body).not_to include('Secret', '/Users/', 'laptop.local', 'abc123')
    end
  end
end
