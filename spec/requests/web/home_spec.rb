require 'rails_helper'

RSpec.describe 'Public website pages', type: :request do

  describe 'GET /' do
    it 'renders the home page with the plants counters' do
      get root_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('plants')
    end
  end

  describe 'GET /about' do
    it 'renders' do
      get about_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET /donate' do
    it 'renders' do
      get donate_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET /terms' do
    it 'renders the licence' do
      get terms_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET /profile' do
    it 'redirects anonymous visitors to sign in' do
      get profile_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'renders for a signed-in user' do
      login_as create(:user), scope: :user
      get profile_path
      expect(response).to have_http_status(:ok)
    end
  end
end
