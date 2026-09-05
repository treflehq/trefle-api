require 'rails_helper'

describe 'Filter/order/range key validation', type: :request do
  let(:user) { create(:user) }
  let(:headers) { {} }

  def get_json(path, params)
    get path, params: params.merge(token: user.token), headers: headers
    JSON.parse(response.body)
  end

  describe 'GET /api/v1/species' do
    it 'rejects an unknown filter_not key with a 400 naming the key' do
      body = get_json('/api/v1/species', filter_not: { spread: 'null' })

      expect(response).to have_http_status(:bad_request)
      expect(body['error']).to eq(true)
      expect(body['message']).to include('spread')
    end

    it 'still filters normally on a known filter_not key' do
      get_json('/api/v1/species', filter_not: { average_height_cm: 'null' })

      expect(response).to have_http_status(:success)
    end

    it 'rejects an unknown filter key with a 400 naming the key' do
      body = get_json('/api/v1/species', filter: { not_a_real_field: 'x' })

      expect(response).to have_http_status(:bad_request)
      expect(body['message']).to include('not_a_real_field')
    end

    it 'still filters normally on a known filter key' do
      get_json('/api/v1/species', filter: { author: 'x' })

      expect(response).to have_http_status(:success)
    end

    it 'rejects an unknown order key with a 400 naming the key' do
      body = get_json('/api/v1/species', order: { not_a_real_field: 'asc' })

      expect(response).to have_http_status(:bad_request)
      expect(body['message']).to include('not_a_real_field')
    end

    it 'still sorts normally on a known order key' do
      get_json('/api/v1/species', order: { scientific_name: 'asc' })

      expect(response).to have_http_status(:success)
    end

    it 'rejects an unknown range key with a 400 naming the key' do
      body = get_json('/api/v1/species', range: { not_a_real_field: '1,2' })

      expect(response).to have_http_status(:bad_request)
      expect(body['message']).to include('not_a_real_field')
    end

    it 'still ranges normally on a known range key' do
      get_json('/api/v1/species', range: { year: '1990,2000' })

      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET /api/v1/species filter[edible] boolean coercion (#277)' do
    # TestSeeds.seed! (spec/rails_helper.rb) loads a shared botanic dataset once per
    # suite, so the table already holds other edible/non-edible species. Scope every
    # query down to these two fixtures by scientific_name instead of asserting on the
    # bare total. `edible` isn't settable directly -- Species#complete_cache_fields
    # derives it from `vegetable`/`edible_part` on save (app/models/species.rb:321).
    let!(:edible_species) { create(:species, vegetable: true) }
    let!(:non_edible_species) { create(:species, vegetable: false) }
    let(:fixture_names) { [edible_species.scientific_name, non_edible_species.scientific_name].join(',') }

    %w[true yes 1 on TRUE Yes On].each do |token|
      it "treats #{token.inspect} as truthy" do
        body = get_json('/api/v1/species', filter: { edible: token, scientific_name: fixture_names })

        expect(response).to have_http_status(:success)
        expect(body['data'].map {|s| s['id'] }).to eq([edible_species.id])
      end
    end

    %w[false no 0 off FALSE No Off].each do |token|
      it "treats #{token.inspect} as falsy" do
        body = get_json('/api/v1/species', filter: { edible: token, scientific_name: fixture_names })

        expect(response).to have_http_status(:success)
        expect(body['data'].map {|s| s['id'] }).to eq([non_edible_species.id])
      end
    end

    it 'rejects a value outside the accepted token set with a 400 naming the field and value' do
      body = get_json('/api/v1/species', filter: { edible: 'banana' })

      expect(response).to have_http_status(:bad_request)
      expect(body['error']).to eq(true)
      expect(body['message']).to include('edible')
      expect(body['message']).to include('banana')
    end
  end

  describe 'GET /api/v1/plants' do
    it 'rejects an unknown filter_not key with a 400 naming the key' do
      body = get_json('/api/v1/plants', filter_not: { spread: 'null' })

      expect(response).to have_http_status(:bad_request)
      expect(body['message']).to include('spread')
    end

    it 'still filters normally on a known filter_not key' do
      get_json('/api/v1/plants', filter_not: { average_height_cm: 'null' })

      expect(response).to have_http_status(:success)
    end

    it 'rejects an unknown filter key with a 400 naming the key' do
      body = get_json('/api/v1/plants', filter: { not_a_real_field: 'x' })

      expect(response).to have_http_status(:bad_request)
      expect(body['message']).to include('not_a_real_field')
    end

    it 'still filters normally on a known filter key' do
      get_json('/api/v1/plants', filter: { author: 'x' })

      expect(response).to have_http_status(:success)
    end

    it 'rejects an unknown order key with a 400 naming the key' do
      body = get_json('/api/v1/plants', order: { not_a_real_field: 'asc' })

      expect(response).to have_http_status(:bad_request)
      expect(body['message']).to include('not_a_real_field')
    end

    it 'still sorts normally on a known order key' do
      get_json('/api/v1/plants', order: { scientific_name: 'asc' })

      expect(response).to have_http_status(:success)
    end

    it 'rejects an unknown range key with a 400 naming the key' do
      body = get_json('/api/v1/plants', range: { not_a_real_field: '1,2' })

      expect(response).to have_http_status(:bad_request)
      expect(body['message']).to include('not_a_real_field')
    end

    it 'still ranges normally on a known range key' do
      get_json('/api/v1/plants', range: { year: '1990,2000' })

      expect(response).to have_http_status(:success)
    end
  end
end
