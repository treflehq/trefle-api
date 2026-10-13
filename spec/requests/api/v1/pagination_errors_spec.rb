require 'rails_helper'

# Pagy's own messages ("expected :page >= 1; got \"abc\"") used to surface
# as-is, with a 404. An unusable page number is a request error: 400, in the
# error envelope, worded for the client, with the last page number when the
# requested one is past it.
RSpec.describe 'Pagination errors', type: :request do
  let(:user) { create(:user) }

  %w[0 -1 abc].each do |value|
    describe "GET /api/v1/species?page=#{value}" do
      before { get '/api/v1/species', params: { token: user.token, page: value } }

      it_behaves_like 'renders API errors', status: :bad_request, code: 'bad_request'

      it 'says the page must be a positive integer, quoting the value' do
        expect(JSON.parse(response.body)['message']).to eq("page must be a positive integer; got #{value.inspect}")
      end
    end
  end

  # Page 2000: past any test table, within the depth cap (#367) that would
  # otherwise answer first.
  describe 'GET /api/v1/species past the last page' do
    let(:last_page) { (Species.count / PerPage::DEFAULT.to_f).ceil }

    before { get '/api/v1/species', params: { token: user.token, page: 2000 } }

    it_behaves_like 'renders API errors', status: :bad_request, code: 'bad_request'

    it 'names the requested page and the last one, in the message and in details' do
      body = JSON.parse(response.body)

      expect(body['message']).to eq("page 2000 is beyond the last page #{last_page}")
      expect(body['details']).to eq('last_page' => last_page)
    end
  end

  describe 'GET /api/v1/species?page=1&per_page=100 past the last page' do
    before { get '/api/v1/species', params: { token: user.token, page: 2, per_page: 100 } }

    it 'computes the last page from the requested page size' do
      expect(Species.count).to be <= 100
      expect(response).to have_http_status(:bad_request)
      expect(JSON.parse(response.body)['message']).to eq('page 2 is beyond the last page 1')
    end
  end

  describe 'GET /api/v1/genus?page=abc (a collection without the cached count)' do
    before { get '/api/v1/genus', params: { token: user.token, page: 'abc' } }

    it_behaves_like 'renders API errors', status: :bad_request, code: 'bad_request'

    it 'says the page must be a positive integer' do
      expect(JSON.parse(response.body)['message']).to eq('page must be a positive integer; got "abc"')
    end
  end

  describe 'GET /api/v1/species/search?page=abc' do
    before { get '/api/v1/species/search', params: { token: user.token, q: 'Abies', page: 'abc' } }

    it_behaves_like 'renders API errors', status: :bad_request, code: 'bad_request'

    it 'says the page must be a positive integer' do
      expect(JSON.parse(response.body)['message']).to eq('page must be a positive integer; got "abc"')
    end
  end

  describe 'GET /api/v1/species/search past the last page' do
    # Page 400: deep enough to overflow any test index, shallow enough to
    # stay under OpenSearch's 10,000-hit result window.
    before { get '/api/v1/species/search', params: { token: user.token, q: 'Abies', page: 400 } }

    it_behaves_like 'renders API errors', status: :bad_request, code: 'bad_request'

    it 'names the requested page and the last one' do
      body = JSON.parse(response.body)

      expect(body['message']).to match(/\Apage 400 is beyond the last page \d+\z/)
      expect(body['details']['last_page']).to be_a(Integer)
    end
  end

  describe 'GET /api/v1/species?page=1 (a valid page)' do
    before { get '/api/v1/species', params: { token: user.token, page: 1 } }

    it 'is unaffected' do
      expect(response).to have_http_status(:ok)
    end
  end
end
