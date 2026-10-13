require 'rails_helper'

# #217 / #132: client-controlled page size on every /api/v1 collection.
# `per_page` is the parameter, `limit` its alias (the search endpoints took
# it, uncapped, before); 1..PerPage::MAX, default PerPage::DEFAULT. Anything
# else is a 400 in the error envelope, never a silent clamp.
RSpec.describe 'Collection page size (per_page)', type: :request do
  let(:user) { create(:user) }

  def get_json(path, params = {})
    get path, params: params.merge(token: user.token)
    JSON.parse(response.body)
  end

  describe 'GET /api/v1/species' do
    # TestSeeds leaves a handful of species; top the table up past the
    # default page size so the default is observable.
    before { 20.times { create(:species) } }

    it 'defaults to 20 items per page and echoes page and page size in meta' do
      body = get_json('/api/v1/species')

      expect(response).to have_http_status(:ok)
      expect(Species.count).to be > PerPage::DEFAULT
      expect(body['data'].size).to eq(PerPage::DEFAULT)
      expect(body['meta']).to include('total' => Species.count, 'page' => 1, 'per_page' => PerPage::DEFAULT)
      expect(body['links']['self']).not_to include('per_page')
    end

    it 'honours per_page and carries it in every pagination link' do
      body = get_json('/api/v1/species', per_page: 5, page: 2)

      expect(response).to have_http_status(:ok)
      expect(body['data'].size).to eq(5)
      expect(body['meta']).to include('page' => 2, 'per_page' => 5)
      expect(body['links'].keys).to contain_exactly('self', 'first', 'prev', 'next', 'last')
      body['links'].each_value {|link| expect(link).to include('per_page=5') }
      expect(body['links']['prev']).to include('page=1')
      expect(body['links']['next']).to include('page=3')
      expect(body['links']['last']).to include("page=#{(Species.count / 5.0).ceil}")
    end

    it 'accepts limit as an alias and normalizes it to per_page in the links' do
      body = get_json('/api/v1/species', limit: 3)

      expect(response).to have_http_status(:ok)
      expect(body['data'].size).to eq(3)
      expect(body['meta']['per_page']).to eq(3)
      expect(body['links']['next']).to include('per_page=3')
      expect(body['links']['next']).not_to include('limit=')
    end

    it 'serves up to 100 items per page' do
      body = get_json('/api/v1/species', per_page: PerPage::MAX)

      expect(response).to have_http_status(:ok)
      expect(body['data'].size).to eq([Species.count, PerPage::MAX].min)
      expect(body['meta']['per_page']).to eq(PerPage::MAX)
    end

    {
      '0' => 'zero',
      '-1' => 'negative',
      'abc' => 'not a number',
      '1.5' => 'not an integer',
      '101' => 'above the maximum'
    }.each do |value, label|
      it "rejects per_page=#{value} (#{label}) with a 400 naming the accepted range" do
        body = get_json('/api/v1/species', per_page: value)

        expect(response).to have_http_status(:bad_request)
        expect(body['error']).to eq(true)
        expect(body['code']).to eq('bad_request')
        expect(body['message']).to include('per_page must be an integer between 1 and 100')
        expect(body['message']).to include(value.inspect)
      end
    end

    it 'rejects an invalid limit the same way, naming the parameter the client used' do
      body = get_json('/api/v1/species', limit: 1000)

      expect(response).to have_http_status(:bad_request)
      expect(body['message']).to include('limit must be an integer between 1 and 100')
    end

    it 'keeps the row horizon of the depth cap: a bigger page cannot reach deeper than the default one' do
      deepest = WithCachedCount::MAX_OFFSET / PerPage::MAX
      body = get_json('/api/v1/species', per_page: PerPage::MAX, page: deepest + 1)

      expect(response).to have_http_status(:bad_request)
      expect(body['message']).to include("deepest page at this page size is #{deepest}")
    end
  end

  describe 'GET /api/v1/species/search' do
    it 'honours per_page' do
      body = get_json('/api/v1/species/search', q: 'Abies', per_page: 1)

      expect(response).to have_http_status(:ok)
      expect(body['meta']['per_page']).to eq(1)
      expect(body['data'].size).to be <= 1
      expect(body['links']['self']).to include('per_page=1')
    end

    it 'caps limit at 100 like every other collection (it used to be uncapped)' do
      body = get_json('/api/v1/species/search', q: 'Abies', limit: 500)

      expect(response).to have_http_status(:bad_request)
      expect(body['message']).to include('limit must be an integer between 1 and 100')
    end
  end

  describe 'every other collection' do
    %w[
      /api/v1/plants
      /api/v1/plants/search?q=Abies
      /api/v1/genus
      /api/v1/genus/abies/species
      /api/v1/genus/abies/plants
      /api/v1/families
      /api/v1/kingdoms
      /api/v1/subkingdoms
      /api/v1/divisions
      /api/v1/division_classes
      /api/v1/division_orders
      /api/v1/distributions
      /api/v1/species/abies-alba/synonyms
      /api/v1/species/abies-alba/corrections
      /api/v1/corrections
    ].each do |path|
      it "applies per_page on #{path}" do
        body = get_json(path, per_page: 1)

        expect(response).to have_http_status(:ok)
        expect(body['meta']['per_page']).to eq(1)
        expect(body['data'].size).to be <= 1
        expect(body['links']['self']).to include('per_page=1')
      end
    end
  end
end
