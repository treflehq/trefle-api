require 'rails_helper'

RSpec.describe 'Explore pages', type: :request do

  describe 'GET /explore' do
    it 'lists species' do
      get explore_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(Species.order(gbif_score: :desc).first.scientific_name)
    end

    it 'features the most observed species first' do
      top = Species.order(:id).last
      top.update_columns(gbif_score: 1_000_000_000)

      get explore_path
      first_card = Nokogiri::HTML(response.body).at_css('a[href^="/explore/species/"]')
      expect(first_card['href']).to eq(explore_species_path(top))
    end

    it 'searches species through the search engine', search: true do
      get explore_path, params: { search: 'Abies' }
      expect(response).to have_http_status(:ok)
    end

    it 'renders a tinted leaf placeholder for species without a photo, not a background-image div' do
      species = Species.order(gbif_score: :desc).first
      species.update!(main_image_url: nil)

      get explore_path
      expect(response.body).not_to include('background-image')

      card = Nokogiri::HTML.fragment(response.body).at_css("a[href=\"#{explore_species_path(species)}\"]")
      expect(card.at_css('div.species-grid-item-photo--empty svg.fa-leaf')).not_to be_nil
    end

    it 'renders a real, lazy-loaded, sized <img> for species that have a photo' do
      species = Species.order(gbif_score: :desc).first
      species.update!(main_image_url: 'https://bs.plantnet.org/image/o/abc123.jpg')

      get explore_path
      card = Nokogiri::HTML.fragment(response.body).at_css("a[href=\"#{explore_species_path(species)}\"]")
      img = card.at_css('img')

      expect(img['src']).to eq('https://bs.plantnet.org/image/m/abc123.jpg')
      expect(img['loading']).to eq('lazy')
      expect(img['decoding']).to eq('async')
      expected_alt = species.common_name.present? ? "#{species.scientific_name} (#{species.common_name})" : species.scientific_name
      expect(img['alt']).to eq(expected_alt)
      expect(img['width']).to be_present
      expect(img['height']).to be_present
    end

    it 'renders 404, not 500, for a page number past the last page' do
      get explore_path, params: { page: 1_003_855_986 }
      expect(response).to have_http_status(:not_found)
    end

    it 'renders 404, not 500, for a non-numeric page' do
      get explore_path, params: { page: 'not-a-number' }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'GET /explore browse filters and sorts' do
    def first_card_name
      h2 = Nokogiri::HTML.fragment(response.body).at_css('.explore-grid__cell .species-grid-item h2')
      h2.css('svg, style').remove # inline duotone icons carry a <style> block
      h2.text.strip
    end

    it 'filters by rank' do
      variety = Species.order(:id).first
      variety.update_columns(rank: Species.ranks['var'])

      get explore_path, params: { rank: 'var' }
      expect(response.body).to include(variety.scientific_name)
      expect(response.body).not_to include(Species.species_rank.order(gbif_score: :desc).first.scientific_name)
    end

    it 'ignores an unknown rank instead of erroring' do
      get explore_path, params: { rank: 'cultivar' }
      expect(response).to have_http_status(:ok)
    end

    it 'filters by family name' do
      species = Species.order(:id).first
      species.update_columns(family_name: 'Testaceae')

      get explore_path, params: { family: 'Testaceae' }
      expect(response.body).to include(species.scientific_name)
      expect(response.body).to include('Showing 1&ndash;1 of 1 plants')
    end

    it 'keeps only species with an image when asked to' do
      bare = Species.order(:id).first
      bare.update_columns(main_image_url: nil)

      get explore_path, params: { images: '1' }
      expect(response.body).not_to include(bare.scientific_name)
    end

    it 'sorts by completion ratio' do
      most_complete = Species.order(:id).first
      most_complete.update_columns(completion_ratio: 99)

      get explore_path, params: { sort: 'complete' }
      expect(first_card_name).to eq(most_complete.scientific_name)
    end

    it 'sorts by scientific name' do
      get explore_path, params: { sort: 'name' }
      expect(first_card_name).to eq(Species.order(:scientific_name).first.scientific_name)
    end

    it 'marks the active filter chip and lets it toggle back off' do
      get explore_path, params: { vegetable: '1' }
      chip = Nokogiri::HTML.fragment(response.body).css('a.explore-chip--active').find {|a| a.text == 'Vegetable' }
      expect(chip).not_to be_nil
      expect(chip['href']).not_to include('vegetable=1')
    end

    it 'renders the empty state when nothing matches' do
      get explore_path, params: { family: 'Nonexistaceae' }
      expect(response.body).to include('No plant matches this search.')
      expect(response.body).to include('clear the filters')
    end

    it 'shows each card with its family and completion percentage' do
      species = Species.order(gbif_score: :desc).first
      species.update_columns(completion_ratio: 42, family_name: 'Pinaceae')

      get explore_path
      card = Nokogiri::HTML.fragment(response.body).css('.explore-grid__cell').find do |cell|
        cell.text.include?(species.scientific_name)
      end
      expect(card.at_css('.explore-grid__family').text).to eq('Pinaceae')
      expect(card.at_css('.explore-grid__completeness-value').text).to eq('42%')
    end

    it 'links the corrections queue from the contribute band' do
      get explore_path
      expect(response.body).to include('Something missing or wrong?')
      expect(response.body).to include(explore_record_corrections_path(status: :pending))
    end
  end

  describe 'GET /explore/species/:id' do
    it 'renders a species page by slug' do
      species = Species.friendly.find('abies-alba')
      get explore_species_path(species)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Abies alba')
    end

    it 'renders a real <img> header photo for a species that has one, with no background-image left' do
      species = Species.friendly.find('abies-alba')
      species.update!(main_image_url: 'https://bs.plantnet.org/image/o/abc123.jpg')

      get explore_species_path(species)
      expect(response.body).not_to include('background-image')

      img = Nokogiri::HTML.fragment(response.body).at_css('.species-lead-image img')
      expect(img['src']).to eq('https://bs.plantnet.org/image/m/abc123.jpg')
      expect(img['loading']).to eq('lazy')
      expect(img['alt']).to be_present
    end

    it 'labels the sidebar entry Overview instead of Informations (#238)' do
      species = Species.friendly.find('abies-alba')
      get explore_species_path(species)

      expect(response.body).to include('Overview')
      expect(response.body).not_to include('Informations')
    end

    it 'shows the species completion percentage next to the title (#238)' do
      species = Species.friendly.find('abies-alba')
      species.update_column(:completion_ratio, 42)

      get explore_species_path(species)

      badge = Nokogiri::HTML.fragment(response.body).at_css('.species-completion')
      expect(badge.text).to include('42%')
    end

    it 'falls back to 0% when the completion ratio has never been computed' do
      species = Species.friendly.find('abies-alba')
      species.update_column(:completion_ratio, nil)

      get explore_species_path(species)

      badge = Nokogiri::HTML.fragment(response.body).at_css('.species-completion')
      expect(badge.text).to include('0%')
    end

    it 'cites the author and year after the scientific name (#439)' do
      species = Species.friendly.find('abies-alba')
      species.update_columns(author: 'Mill.', year: 1768)

      get explore_species_path(species)

      title = Nokogiri::HTML.fragment(response.body).at_css('.species-lead h1')
      expect(title.text.squish).to start_with('Abies alba Mill., 1768')
      expect(title.at_css('.species-authorship').text).to eq('Mill., 1768')
    end

    it 'cites the year alone when the author is unknown, with no placeholder text (#439)' do
      species = Species.friendly.find('abies-alba')
      species.update_columns(author: nil, year: 1768)

      get explore_species_path(species)

      title = Nokogiri::HTML.fragment(response.body).at_css('.species-lead h1')
      expect(title.at_css('.species-authorship').text).to eq('1768')
      expect(response.body).not_to include('No author', 'No year')
    end

    it 'leaves the authorship out when the name has neither author nor year (#439)' do
      species = Species.friendly.find('abies-alba')
      species.update_columns(author: nil, year: nil)

      get explore_species_path(species)

      title = Nokogiri::HTML.fragment(response.body).at_css('.species-lead h1')
      expect(title.text.squish).to start_with('Abies alba ')
      expect(title.at_css('.species-authorship')).to be_nil
      expect(response.body).not_to include('No author', 'No year', 'No bibliography')
    end

    it 'ships the ecological indicators as Ellenberg classes, not as lux or µg figures (#439)' do
      get explore_species_path(Species.friendly.find('abies-alba'))

      container = Nokogiri::HTML.fragment(response.body).at_css('#explore-species-page')
      table = JSON.parse(container['data-ecological-indicators'])

      expect(table['indicators'].keys).to contain_exactly('light', 'atmospheric_humidity', 'ground_humidity', 'soil_nutriments', 'soil_salinity')
      expect(table['indicators']['light'].values_at('min', 'max')).to eq([1, 9])
      expect(table['indicators']['light']['classes']['7']).to eq('half-light to light')
      expect(table['indicators']['ground_humidity']['max']).to eq(12)
      expect(table['indicators']['soil_salinity']['classes']['0']).to eq('absent from saline soils')
      expect(table['note']).to include('not what an individual plant tolerates')
      expect(response.body).not_to include(' lux', 'µg', 'Cl−')
    end

    it 'says which name is accepted when reached through a synonym slug (#439)' do
      accepted = Species.friendly.find('abies-alba')
      Synonym.create!(record: accepted, name: 'Abies pectinata', author: 'DC.')

      get '/explore/species/abies-pectinata'

      expect(response).to have_http_status(:ok)
      notice = Nokogiri::HTML.fragment(response.body).at_css('.species-name-notice')
      expect(notice.text.squish).to include('Abies pectinata DC. is a synonym', 'The accepted name is Abies alba Aubin1, 1901')
    end

    it 'flags a name whose status is not accepted and links the species that holds it as a synonym (#439)' do
      doubtful = Species.friendly.find('abies-alba')
      accepted = Species.where.not(id: doubtful.id).order(:id).first
      doubtful.update_columns(status: Species.statuses['doubtful'])
      Synonym.create!(record: accepted, name: doubtful.scientific_name, author: 'Mill.')

      get explore_species_path(doubtful)

      notice = Nokogiri::HTML.fragment(response.body).at_css('.species-name-notice')
      expect(notice.text.squish).to include('Not an accepted name (status: doubtful)', "The accepted name is #{accepted.scientific_name} #{accepted.author}, #{accepted.year}")
      expect(notice.at_css('a')['href']).to eq(explore_species_path(accepted))
    end

    it 'says so when a name that is not accepted has no accepted record claiming it yet (#439)' do
      unknown = Species.friendly.find('abies-alba')
      unknown.update_columns(status: Species.statuses['unknown'])

      get explore_species_path(unknown)

      notice = Nokogiri::HTML.fragment(response.body).at_css('.species-name-notice')
      expect(notice.text.squish).to include('Not an accepted name (status: unknown)', 'No accepted name is recorded for it yet')
      expect(notice.at_css('a')).to be_nil
    end

    it 'shows no name notice on an accepted species reached by its own slug' do
      get explore_species_path(Species.friendly.find('abies-alba'))

      expect(Nokogiri::HTML.fragment(response.body).at_css('.species-name-notice')).to be_nil
    end
  end

  describe 'GET /explore/genus' do
    it 'redirects the unimplemented listing to the species exploration' do
      get explore_genus_index_path
      expect(response).to redirect_to(explore_path)
    end

    it 'renders a genus page with its species' do
      genus = Genus.find_by!(name: 'Abies')
      get explore_genus_path(genus)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Abies')
    end

    it 'renders a leaf placeholder in the genus header when none of its species has a photo' do
      genus = Genus.find_by!(name: 'Abies')
      genus.species.update_all(main_image_url: nil)

      get explore_genus_path(genus)

      placeholder = Nokogiri::HTML.fragment(response.body).at_css('.species-correction-image .species-correction-image-photo--empty svg.fa-leaf')
      expect(placeholder).not_to be_nil
    end

    it 'renders 404, not 500, for a page number past the last page' do
      genus = Genus.find_by!(name: 'Abies')
      get explore_genus_path(genus, page: 1_003_855_986)
      expect(response).to have_http_status(:not_found)
    end

    it 'renders 404, not 500, for a non-numeric page' do
      genus = Genus.find_by!(name: 'Abies')
      get explore_genus_path(genus, page: 'not-a-number')
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'GET /explore/corrections' do
    before do
      create(:record_correction, notes: 'Testing correction listing')
    end

    it 'lists corrections' do
      get explore_record_corrections_path
      expect(response).to have_http_status(:ok)
    end

    it 'lists the newest correction first, dated with its year' do
      create(:record_correction, notes: 'Older one', created_at: Time.zone.local(2025, 11, 5, 12, 34))
      create(:record_correction, notes: 'Newer one', created_at: Time.zone.local(2026, 10, 13, 7, 15))
      RecordCorrection.where(notes: 'Testing correction listing').update_all(created_at: Time.zone.local(2024, 3, 1))

      get explore_record_corrections_path

      expect(response.body.index('13 Oct 2026')).to be < response.body.index('5 Nov 2025')
      expect(response.body.index('5 Nov 2025')).to be < response.body.index('1 Mar 2024')
    end

    it 'filters by species' do
      species = RecordCorrection.first.record
      get explore_record_corrections_path(species_id: species.slug)
      expect(response).to have_http_status(:ok)
    end

    it 'renders a correction page' do
      get explore_record_correction_path(RecordCorrection.first)
      expect(response).to have_http_status(:ok)
    end

    it 'renders 404, not 500, for a page number past the last page' do
      get explore_record_corrections_path(page: 1_003_855_986)
      expect(response).to have_http_status(:not_found)
    end

    it 'renders 404, not 500, for a non-numeric page' do
      get explore_record_corrections_path(page: 'not-a-number')
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'GET /explore/data' do
    it 'redirects to the database overview on the home page' do
      get '/explore/data'
      expect(response).to redirect_to('/#data')
      expect(response).to have_http_status(:moved_permanently)
    end
  end
end
