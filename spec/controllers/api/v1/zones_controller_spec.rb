require 'rails_helper'

RSpec.describe Api::V1::ZonesController do
  describe 'GET #index' do
    let(:user) { create(:user) }
    let(:params) { { token: user.token } }

    it 'returns http success' do
      get :index, params: params

      expect(response).to have_http_status(:success)
    end

    it_behaves_like 'a filterable collection', Zone, Api::V1::ZonesController::FILTERABLE_FIELDS
    it_behaves_like 'an orderable collection', Zone, Api::V1::ZonesController::ORDERABLE_FIELDS
    it_behaves_like 'a searchable collection', Zone
  end
end
