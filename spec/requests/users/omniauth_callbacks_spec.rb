require 'rails_helper'

RSpec.describe 'Users::OmniauthCallbacks', type: :request do
  before do
    OmniAuth.config.test_mode = true
  end

  after do
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:github] = nil
  end

  def mock_github_auth(uid: '1', email: 'octocat@example.com', nickname: 'octocat', name: 'Octo Cat')
    OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(
      provider: 'github',
      uid: uid,
      info: OmniAuth::AuthHash::InfoHash.new(email: email, nickname: nickname, name: name)
    )
    Rails.application.env_config['omniauth.auth'] = OmniAuth.config.mock_auth[:github]
  end

  describe 'GET /users/auth/github/callback' do
    it 'creates and signs in a brand new user' do
      mock_github_auth(uid: '999', email: 'newcomer@example.com')

      expect do
        get user_github_omniauth_callback_path
      end.to change(User, :count).by(1)

      user = User.find_by(email: 'newcomer@example.com')
      expect(user.provider).to eq('github')
      expect(user.uid).to eq('999')
      expect(response).to redirect_to(root_path)
    end

    it 'signs in an existing user matched by provider and uid' do
      user = create(:user, provider: 'github', uid: '42')
      mock_github_auth(uid: '42', email: 'someone-else@example.com')

      expect do
        get user_github_omniauth_callback_path
      end.not_to change(User, :count)

      expect(response).to redirect_to(root_path)
      expect(user.reload.email).not_to eq('someone-else@example.com')
    end

    it 'links an existing account found by email and signs it in' do
      user = create(:user, email: 'legacy@example.com', provider: nil, uid: nil)
      mock_github_auth(uid: '777', email: 'legacy@example.com', nickname: 'legacy_gh')

      expect do
        get user_github_omniauth_callback_path
      end.not_to change(User, :count)

      expect(user.reload.provider).to eq('github')
      expect(user.uid).to eq('777')
      expect(user.github_username).to eq('legacy_gh')
    end

    it 'links the GitHub account to the currently signed-in user when creation fails' do
      current = create(:user)
      login_as current, scope: :user
      mock_github_auth(uid: '555', email: nil)

      expect do
        get user_github_omniauth_callback_path
      end.not_to change(User, :count)

      expect(current.reload.provider).to eq('github')
      expect(current.uid).to eq('555')
      expect(response).to redirect_to(edit_user_registration_path)
    end

    it 'redirects to sign up with the errors when nobody is signed in and creation fails' do
      mock_github_auth(uid: '333', email: nil)

      get user_github_omniauth_callback_path

      expect(response).to redirect_to(new_user_registration_url)
    end
  end

  describe 'GET /users/auth/github/callback (failure)' do
    it 'redirects home with an alert' do
      OmniAuth.config.mock_auth[:github] = :invalid_credentials

      get user_github_omniauth_callback_path

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq('Could not authenticate you from GitHub.')
    end
  end
end
