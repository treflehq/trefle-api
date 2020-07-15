require 'rails_helper'

RSpec.describe Api::V1::SpeciesController do
  describe 'GET #index' do
    let(:user) { create(:user) }
    let(:params) { { token: user.token } }

    it 'returns http success' do
      get :index, params: params

      expect(response).to have_http_status(:success)
    end

    it_behaves_like 'a searchable collection', Species
    it_behaves_like 'a rangeable collection', Species, Api::V1::SpeciesController::RANGEABLE_FIELDS
    it_behaves_like 'a filterable collection', Species, Api::V1::SpeciesController::FILTERABLE_FIELDS
    it_behaves_like 'a filterable_not collection', Species, Api::V1::SpeciesController::FILTERABLE_NOT_FIELDS
    it_behaves_like 'an orderable collection', Species, Api::V1::SpeciesController::ORDERABLE_FIELDS

  end
end
