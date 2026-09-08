require 'rails_helper'

RSpec.describe 'Terms acceptance', type: :request do
  # A user "pending terms" mimics an account created before this feature
  # shipped (nil terms_accepted_at) as well as a brand new GitHub OAuth
  # sign-up (see Users::OmniauthCallbacksController -- it never sets
  # accepts_terms, on purpose).
  let(:pending_user) { create(:user, accepts_terms: false) }

  describe 'the web-wide gate (RequiresTermsAcceptance, included in ApplicationController and Explore::ExploreController)' do
    it 'redirects a signed-in user with no recorded acceptance away from the app' do
      login_as pending_user, scope: :user

      get profile_path

      expect(response).to redirect_to(new_terms_acceptance_path(return_to: profile_path))
    end

    it 'also gates explore/ pages, not just home/profile -- a pending user cannot browse species either' do
      login_as pending_user, scope: :user

      get explore_path

      expect(response).to redirect_to(new_terms_acceptance_path(return_to: explore_path))
    end

    it 'redirects a signed-in user whose accepted version is stale' do
      # Built stale from the start (accepts_terms: false so the before_save
      # callback doesn't stamp it as current) rather than accepted-then-mutated:
      # Devise's :trackable module re-saves current_user on sign-in, which
      # would silently re-run the acceptance callback and heal the staleness
      # if accepts_terms were still truthy on that same in-memory object.
      stale_user = create(:user, accepts_terms: false, terms_accepted_at: 1.year.ago, terms_version: 'some-old-version')
      login_as stale_user, scope: :user

      get profile_path

      expect(response).to redirect_to(new_terms_acceptance_path(return_to: profile_path))
    end

    it 'lets a user who is up to date through untouched' do
      login_as create(:user), scope: :user

      get profile_path

      expect(response).to have_http_status(:ok)
    end

    it 'does not gate anonymous visitors' do
      get root_path

      expect(response).to have_http_status(:ok)
    end

    it 'does not gate Devise pages, so a pending user can still sign out' do
      login_as pending_user, scope: :user

      get edit_user_registration_path

      expect(response).to have_http_status(:ok)
    end

    it 'never gates the JSON API -- a token keeps working regardless of pending terms' do
      get '/api/v1/me', headers: { 'Authorization' => "Bearer #{pending_user.token}" }

      expect(response).to have_http_status(:ok)
    end

    it 'never gates /api/v1 routes even for a browser session with a pending-terms cookie (Api::V1::HomeController oddly inherits ApplicationController)' do
      login_as pending_user, scope: :user

      get '/api/v1/'

      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET /terms_acceptance/new' do
    it 'redirects anonymous visitors to sign in' do
      get new_terms_acceptance_path

      expect(response).to redirect_to(new_user_session_path)
    end

    it 'renders the prompt for a pending user' do
      login_as pending_user, scope: :user

      get new_terms_acceptance_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Terms of Use')
    end
  end

  describe 'POST /terms_acceptance' do
    it 'records acceptance and redirects to return_to when the box is checked' do
      login_as pending_user, scope: :user

      post terms_acceptance_path, params: { user: { accepts_terms: '1' }, return_to: profile_path }

      expect(response).to redirect_to(profile_path)
      pending_user.reload
      expect(pending_user.terms_accepted_at).to be_present
      expect(pending_user.terms_version).to eq(TERMS_VERSION)
    end

    it 'falls back to root_path when return_to is missing' do
      login_as pending_user, scope: :user

      post terms_acceptance_path, params: { user: { accepts_terms: '1' } }

      expect(response).to redirect_to(root_path)
    end

    it 'ignores an off-site return_to (open-redirect guard)' do
      login_as pending_user, scope: :user

      post terms_acceptance_path, params: { user: { accepts_terms: '1' }, return_to: 'https://evil.example/phish' }

      expect(response).to redirect_to(root_path)
    end

    it 'ignores a backslash return_to that browsers normalize into a protocol-relative redirect' do
      login_as pending_user, scope: :user

      post terms_acceptance_path, params: { user: { accepts_terms: '1' }, return_to: '/\\evil.example' }

      expect(response).to redirect_to(root_path)
    end

    it 'ignores a mixed slash/backslash return_to' do
      login_as pending_user, scope: :user

      post terms_acceptance_path, params: { user: { accepts_terms: '1' }, return_to: '/\\/evil.example' }

      expect(response).to redirect_to(root_path)
    end

    it 'refuses to record acceptance when the box is left unchecked' do
      login_as pending_user, scope: :user

      post terms_acceptance_path, params: { user: { accepts_terms: '0' } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(pending_user.reload.terms_accepted_at).to be_nil
    end

    it 'lets a freshly accepted user through the gate on the very next request' do
      login_as pending_user, scope: :user
      post terms_acceptance_path, params: { user: { accepts_terms: '1' } }

      get profile_path

      expect(response).to have_http_status(:ok)
    end
  end
end
