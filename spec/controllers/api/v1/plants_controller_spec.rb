require 'rails_helper'

RSpec.describe Api::V1::PlantsController do
  describe 'GET #index' do
    let(:user) { create(:user) }
    let(:params) { { token: user.token } }

    it 'returns http success' do
      get :index, params: params

      expect(response).to have_http_status(:success)
      puts response.body
      json_response = JSON.parse(response.body)
    end

    it_behaves_like 'a searchable collection', Species.plants
    it_behaves_like 'a rangeable collection', Species.plants, Api::V1::SpeciesController::RANGEABLE_FIELDS
    it_behaves_like 'a filterable collection', Species.plants, Api::V1::SpeciesController::FILTERABLE_FIELDS
    it_behaves_like 'a filterable_not collection', Species.plants, Api::V1::SpeciesController::FILTERABLE_NOT_FIELDS
    it_behaves_like 'an orderable collection', Species.plants, Api::V1::SpeciesController::ORDERABLE_FIELDS

  end
end
