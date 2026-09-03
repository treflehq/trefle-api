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
