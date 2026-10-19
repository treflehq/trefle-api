require 'rails_helper'

RSpec.describe 'Management::Users', type: :request do
  let(:admin) { create(:admin) }

  describe 'access' do
    it 'refuses a non-admin' do
      login_as create(:user), scope: :user

      get management_users_path

      expect(response).to have_http_status(:found)
      expect(response.location).to start_with(root_url)
      expect(response.location).to include('status=401')
    end
  end

  context 'as an admin' do
    before { login_as admin, scope: :user }

    describe 'GET /management/users' do
      let!(:ada) do
        create(:user, email: 'ada@lovelace.test', name: 'Ada', organization_name: 'Analytical Engines',
                      organization_url: 'https://engines.example', github_username: 'adal')
      end
      let!(:bob) { create(:user, email: 'bob@builder.test', name: 'Bob', organization_name: 'Builders') }

      {
        'email' => 'LOVELACE',
        'name' => 'ada',
        'organization_name' => 'analytical',
        'organization_url' => 'engines.example',
        'github_username' => 'ADAL'
      }.each do |field, term|
        it "matches q against #{field}" do
          get management_users_path, params: { q: term }

          expect(response).to have_http_status(:ok)
          expect(response.body).to include('ada@lovelace.test')
          expect(response.body).not_to include('bob@builder.test')
        end
      end

      it 'treats % in q literally' do
        get management_users_path, params: { q: '%' }

        expect(response.body).not_to include('ada@lovelace.test')
      end

      it 'finds the owner of an exact token' do
        get management_users_path, params: { token: ada.token }

        expect(response.body).to include('ada@lovelace.test')
        expect(response.body).not_to include('bob@builder.test')
      end

      it 'does not match a partial token' do
        get management_users_path, params: { token: ada.token[0, 10] }

        expect(response.body).not_to include('ada@lovelace.test')
      end

      it 'lists everyone without filters and shows the search box' do
        get management_users_path

        expect(response.body).to include('ada@lovelace.test', 'bob@builder.test')
        expect(response.body).to include('name="q"')
      end
    end

    describe 'GET /management/users/:id' do
      let(:user) { create(:user, organization_url: 'https://acme.example') }

      def hour_key(time)
        time.strftime('%y%m%d%H').to_i
      end

      it 'renders the usage panel for a user without user_queries' do
        get management_user_path(user)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('API usage')
        expect(response.body).to include('No requests recorded')
      end

      it 'renders totals, top actions and first/last hour' do
        now = Time.zone.now
        UserQuery.create!(user: user, time: hour_key(now - 1.hour), counter: 10, controller: 'api/v1/species', action: 'index')
        UserQuery.create!(user: user, time: hour_key(now - 3.days), counter: 100, controller: 'api/v1/plants', action: 'show')
        UserQuery.create!(user: user, time: hour_key(now - 20.days), counter: 1000)

        get management_user_path(user)

        body = response.body.gsub(/<[^>]+>/, ' ').gsub(/\s+/, ' ')
        expect(body).to match(/Last 24 h 10 /)
        expect(body).to match(/Last 7 d 110 /)
        expect(body).to match(/Last 30 d 1,110 /)
        expect(body).to include('api/v1/plants#show')
      end

      it 'shows account context' do
        user.update_columns(terms_version: '2025-01', terms_accepted_at: Time.zone.local(2025, 1, 2))

        get management_user_path(user)

        expect(response.body).to include('2025-01', 'https://acme.example')
      end

      it 'masks the token and hides secret columns' do
        user.update_columns(reset_password_token: 'resetsecret123', unlock_token: 'unlocksecret123',
                            confirmation_token: 'confirmsecret123')

        get management_user_path(user)

        expect(response.body).to include(user.token[0, 4], user.token[-4..])
        expect(response.body).not_to include(user.token)
        expect(response.body).not_to include('resetsecret123', 'unlocksecret123', 'confirmsecret123')
      end
    end
  end
end
