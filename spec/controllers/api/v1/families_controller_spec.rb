require 'rails_helper'

RSpec.describe Api::V1::FamiliesController do
  describe 'GET #index' do
    let(:user) { create(:user) }
    let(:params) { { token: user.token } }

    it 'returns http success' do
      get :index, params: params

      expect(response).to have_http_status(:success)
    end

    it_behaves_like 'a filterable collection', Family, Api::V1::FamiliesController::FILTERABLE_FIELDS
    it_behaves_like 'an orderable collection', Family, Api::V1::FamiliesController::ORDERABLE_FIELDS
    it_behaves_like 'a searchable collection', Family

  end
end
