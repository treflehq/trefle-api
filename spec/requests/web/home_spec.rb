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

    it 'counts the corrections of the last 30 days, without the weekly chart' do
      create(:record_correction).tap(&:reject!)

      get root_path

      changes = Nokogiri::HTML(response.body).at_css('#changes')
      expect(changes.text.squish).to include('In the last 30 days')
      tile = changes.css('.home-stat-tiles__tile').find {|t| t.at_css('dd').text == 'corrections reviewed' }
      expect(tile.at_css('dt').text.delete(',').to_i).to be >= 1
      expect(changes.at_css('.home-sparkline')).to be_nil
    end

    it 'states the dataset size from SiteCounts, with no "million" anywhere (#437)' do
      get root_path
      expect(response.body.squish).to include("about #{plants_figure} plants (#{species_figure} records once subspecies")
      expect(response.body).not_to match(/million/i)
    end
  end

  # The figures every page quoting a dataset size must agree on.
  def plants_figure
    ActiveSupport::NumberHelper.number_to_delimited(SiteCounts.approximate(Plant.count))
  end

  def species_figure
    ActiveSupport::NumberHelper.number_to_delimited(SiteCounts.approximate(Species.count))
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

    it 'quotes the same dataset figures as the home page, and no "million" (#437)' do
      get about_path
      expect(response.body.squish).to include("about #{plants_figure} plants (#{species_figure} records with subspecies")
      expect(response.body).not_to match(/million/i)
    end

    it 'tells visitors that Google Analytics is used, instead of claiming no tracking (#437)' do
      get about_path
      privacy = Nokogiri::HTML.fragment(response.body).at_css('#privacy').text
      expect(privacy).to include('Google Analytics')
      expect(privacy).to include('Your account is not sent to Google')
      expect(privacy).not_to include('No third-party tracking')
      expect(response.body).to include('https://policies.google.com/privacy')
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
  end

  describe 'GET /terms' do
    it 'renders the licence' do
      get terms_path
      expect(response).to have_http_status(:ok)
    end

    it 'names the data licence and the attribution clause (#320)' do
      get terms_path
      expect(response.body).to include('CC BY 4.0')
      expect(response.body).to include('Data: Trefle.io')
    end
  end

  describe 'GET /citation' do
    it 'renders the three citation formats' do
      get citation_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Trefle: a global plants API')
      expect(response.body).to include('Trefle. (') # APA
      expect(response.body).to include('@misc{trefle') # BibTeX
    end

    it 'states the data version, asks for the access date and offers RIS' do
      DataRun.create!(runnable: 'Spec::Run', kind: 'import', status: :completed,
                      started_at: Time.utc(2026, 10, 13, 6, 0), finished_at: Time.utc(2026, 10, 13, 6, 40))
      DatasetVersion.reset!

      get citation_path

      expect(response.body).to include('id="dataset-version">2026.10.13<')
      expect(response.body).to include('data version 2026.10.13') # plain text
      expect(response.body).to include('version = {2026.10.13}') # BibTeX
      expect(response.body).to include('urldate = {YYYY-MM-DD}')
      expect(response.body).to include('TY  - DATA') # RIS
      expect(response.body).to include('ET  - Version 2026.10.13')
    ensure
      DatasetVersion.reset!
    end

    it 'co-cites the upstream sources the data actually comes from, TRY and WCVP included' do
      stub_const('CitationSources::MAJOR_THRESHOLD', 1)
      Migrators::SourceLicences.run
      ForeignSource.find_by(slug: 'try') || ForeignSource.create!(name: 'TRY', slug: 'try', url: 'https://www.try-db.org')
      species = create(:species)
      ForeignSourcesPlant.create!(species: species, foreign_source: ForeignSource.find_by!(slug: 'powo'), fid: 'powo-fid')
      SpeciesFact.create!(species: species, attribute_name: 'light', source: 'try', value: '7')

      get citation_path

      sources = response.body[%r{id="citation-sources".*?</table>}m]
      expect(sources).to include('Kattge', 'Govaerts', 'CC-BY-4.0')
      expect(sources).not_to include('Tropicos') # no record comes from it
      expect(response.body).to include('@article{kattge2020try', '@article{govaerts2021wcvp')
      expect(response.body).to include('DO  - 10.1111/gcb.14904')
    end

    it 'shows a "DOI pending" state when no DOI is configured' do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('TREFLE_DOI').and_return(nil)

      get citation_path

      expect(response.body).to include('DOI pending')
    end

    it 'shows the DOI, linked, when configured' do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('TREFLE_DOI').and_return('10.5281/zenodo.1234567')

      get citation_path

      expect(response.body).not_to include('DOI pending')
      expect(response.body).to include('10.5281/zenodo.1234567')
      expect(response.body).to include('https://doi.org/10.5281/zenodo.1234567')
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

  describe 'Google Analytics snippet (#437)' do
    it 'is still loaded, but configured without a user_id for anonymous visitors' do
      get root_path
      expect(response.body).to include("gtag('config', 'G-8VL7KHM5CK');")
      expect(response.body).not_to include('user_id')
    end

    it 'does not hand the account id to Google for signed-in users either' do
      user = create(:user)
      login_as user, scope: :user

      get root_path

      expect(response.body).to include("gtag('config', 'G-8VL7KHM5CK');")
      expect(response.body).not_to include('user_id')
      # Word boundaries: user 8 must not match the 8 in G-8VL7KHM5CK.
      expect(response.body).not_to match(/gtag\('config'.*\b#{user.id}\b/)
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
