require 'rails_helper'

# Every filter and order key the corrections controller advertises used to
# return a 500: the model carried neither the Filterable/Sortable machinery nor
# the scopes those concerns call. The API sweep found 27 of them in one run.
describe 'Corrections filtering and ordering', type: :request do
  let(:user) { create(:user) }

  def get_json(path, params)
    get path, params: params.merge(token: user.token)
    JSON.parse(response.body)
  end

  before { create(:record_correction, user: user, notes: 'a note') }

  Api::V1::RecordCorrectionsController::FILTERABLE_FIELDS.each do |field|
    it "answers rather than raising on filter[#{field}]" do
      get_json('/api/v1/corrections', filter: { field => '1' })

      expect(response).to have_http_status(:success)
    end
  end

  Api::V1::RecordCorrectionsController::ORDERABLE_FIELDS.each do |field|
    it "answers rather than raising on order[#{field}]" do
      get_json('/api/v1/corrections', order: { field => 'asc' })

      expect(response).to have_http_status(:success)
    end
  end

  it 'actually narrows the set rather than ignoring the filter' do
    mine = create(:record_correction, user: user)
    create(:record_correction, user: create(:user))

    body = get_json('/api/v1/corrections', filter: { 'user_id' => user.id })

    expect(response).to have_http_status(:success)
    returned = body['data'].map {|c| c['id'] }
    expect(returned).to include(mine.id)
    expect(RecordCorrection.where(id: returned).pluck(:user_id).uniq).to eq([user.id])
  end

  # An enum only knows its own names. Handing it an unknown one raises inside
  # ActiveRecord, so the scopes filter the value down first.
  it 'returns an empty set for an unknown enum value instead of failing' do
    body = get_json('/api/v1/corrections', filter: { 'change_status' => 'banana' })

    expect(response).to have_http_status(:success)
    expect(body['data']).to be_empty
  end

  it 'still rejects a key that is not advertised at all' do
    body = get_json('/api/v1/corrections', filter: { 'not_a_real_field' => 'x' })

    expect(response).to have_http_status(:bad_request)
    expect(body['message']).to include('not_a_real_field')
  end
end
