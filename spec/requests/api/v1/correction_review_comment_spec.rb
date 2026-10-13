require 'rails_helper'

describe 'Review comment of a correction', type: :request do
  let(:user) { create(:user) }

  it 'tells the submitter why the correction was decided' do
    correction = create(:record_correction, user: user, change_status: :rejected, review_comment: 'No source for the height')

    get "/api/v1/corrections/#{correction.id}", params: { token: user.token }

    expect(response).to have_http_status(:success)
    expect(JSON.parse(response.body).dig('data', 'review_comment')).to eq('No source for the height')
  end
end
