require 'rails_helper'

RSpec.describe Api::V1::GenusController do
  describe 'GET #index' do
    let(:user) { create(:user) }
    let(:params) { { token: user.token } }

    it 'returns http success' do
      get :index, params: params

      expect(response).to have_http_status(:success)
    end

    it_behaves_like 'a filterable collection', Genus, Api::V1::GenusController::FILTERABLE_FIELDS
    it_behaves_like 'an orderable collection', Genus, Api::V1::GenusController::ORDERABLE_FIELDS
    it_behaves_like 'a searchable collection', Genus

  end
end
