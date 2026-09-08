require 'rails_helper'

RSpec.describe 'Management::Families', type: :request do
  before { login_as create(:admin), scope: :user }

  describe 'GET /management/families' do
    it 'renders 200' do
      get management_families_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET /management/families/:id' do
    it 'renders 200' do
      family = create(:family)

      get management_family_path(family)

      expect(response).to have_http_status(:ok)
    end

    it 'links back to the families index' do
      family = create(:family)

      get management_family_path(family)

      expect(response.body).to include(management_families_path)
    end
  end
end
