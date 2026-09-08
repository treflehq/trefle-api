require 'rails_helper'

RSpec.describe 'Public website pages', type: :request do

  describe 'GET /' do
    it 'renders the home page with the plants counters' do
      get root_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('plants')
    end

    it 'does not load the FontAwesome runtime kit, and renders icons as inline svg instead' do
      get root_path
      expect(response.body).not_to include('fontawesome/js/all.min.js')

      fragment = Nokogiri::HTML.fragment(response.body)
      expect(fragment.css('svg.fa-icon')).not_to be_empty
    end

    it 'exposes the home stats presenter backing the redesigned home page (#305)' do
      get root_path
      expect(assigns(:home_stats)).to be_a(HomeStatsPresenter)
    end
  end

  describe 'GET /about' do
    it 'renders' do
      get about_path
      expect(response).to have_http_status(:ok)
    end

    it 'shows the computed team numbers, the rate-limit tiles and the citation' do
      get about_path
      expect(response.body).to include('core maintainers')
      expect(response.body).to include('60 req/min')
      expect(response.body).to include('600 req/min')
      expect(response.body).to include("accessed #{Date.current.iso8601}")
    end

    it 'links every section from the anchor nav' do
      get about_path
      nav = Nokogiri::HTML.fragment(response.body).at_css('.about__nav')
      anchors = nav.css('a').map {|a| a['href'] }
      expect(anchors).to eq(%w[#sources #team #pricing #licence #privacy #contact])
      body = Nokogiri::HTML.fragment(response.body)
      anchors.each {|anchor| expect(body.at_css(anchor)).not_to be_nil }
    end
  end

  describe 'GET /donate' do
    it 'renders' do
      get donate_path
      expect(response).to have_http_status(:ok)
    end

    it 'shows the real sponsor count with a matching verb' do
      User.create!(email: 'sponsor@example.test', password: 'password-123', sponsored_tier: 'bronze')

      get donate_path
      expect(response.body).to include('sponsor currently')
      expect(response.body).to include('supports Trefle through GitHub')
    end

    it 'keeps the sponsor terms and the company tiers' do
      get donate_path
      expect(response.body).to include('Sponsor terms')
      expect(response.body).to include('Bronze')
      expect(response.body).to include('Sponsor on GitHub')
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

  describe 'Footer app version' do
    it 'shows the tagged revision linked to its GitHub release' do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('APP_REVISION').and_return('v2.0.2')

      get root_path

      fragment = Nokogiri::HTML.fragment(response.body)
      link = fragment.at_css('a.app-revision')
      expect(link.text).to eq('v2.0.2')
      expect(link['href']).to eq('https://github.com/treflehq/trefle-api/releases/tag/v2.0.2')
    end

    it 'falls back to "dev" with no link when APP_REVISION is unset' do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('APP_REVISION').and_return(nil)

      get root_path

      fragment = Nokogiri::HTML.fragment(response.body)
      expect(fragment.at_css('a.app-revision')).to be_nil
      expect(fragment.at_css('span.app-revision').text).to eq('dev')
    end
  end
end
