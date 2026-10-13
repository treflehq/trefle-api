require 'rails_helper'

# /species and /plants refuse pages past the 50,000-row horizon
# (WithCachedCount). The full collections run past it, so `links.last` used
# to point at a page that answers 400. The links now stop at the deepest
# reachable page. The horizon is shrunk here so a handful of rows cross it.
RSpec.describe 'Pagination links past the depth cap', type: :request do
  let(:user) { create(:user) }

  before do
    stub_const('WithCachedCount::MAX_PAGE_DEPTH', 3)
    stub_const('WithCachedCount::MAX_OFFSET', 6)
    10.times { create(:species) }
  end

  def get_json(path, params = {})
    get path, params: params.merge(token: user.token)
    JSON.parse(response.body)
  end

  def page_of(link)
    Rack::Utils.parse_nested_query(URI.parse(link).query)['page'].to_i
  end

  it 'caps links.last at the deepest page the page size can reach' do
    body = get_json('/api/v1/species', per_page: 2)

    expect(response).to have_http_status(:ok)
    expect(body['meta']['total']).to be > 6
    expect(page_of(body['links']['last'])).to eq(3)

    get '/api/v1/species', params: { token: user.token, per_page: 2, page: 3 }
    expect(response).to have_http_status(:ok)
    get '/api/v1/species', params: { token: user.token, per_page: 2, page: 4 }
    expect(response).to have_http_status(:bad_request)
  end

  it 'stops links.next at the deepest reachable page' do
    body = get_json('/api/v1/species', per_page: 2, page: 3)

    expect(body['links']).not_to have_key('next')
    expect(page_of(body['links']['last'])).to eq(3)
  end

  it 'follows the row horizon when it comes before the page cap' do
    body = get_json('/api/v1/species', per_page: 4)

    # Page 2 starts at row 4 (< 6), page 3 at row 8: the deepest page is 2.
    expect(page_of(body['links']['last'])).to eq(2)
  end

  it 'applies to /plants as well' do
    body = get_json('/api/v1/plants', per_page: 2)

    expect(page_of(body['links']['last'])).to be <= 3
  end

  it 'leaves the other collections alone' do
    body = get_json('/api/v1/genus', per_page: 1)

    expect(page_of(body['links']['last'])).to eq(body['meta']['total'])
  end
end
