require 'rails_helper'

RSpec.describe 'Explore pages', type: :request do

  describe 'GET /explore' do
    it 'lists species' do
      get explore_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(Species.order(wiki_score: :desc).first.scientific_name)
    end

    it 'searches species through the search engine', search: true do
      get explore_path, params: { search: 'Abies' }
      expect(response).to have_http_status(:ok)
    end

    it 'renders a tinted leaf placeholder for species without a photo, not a background-image div' do
      species = Species.order(wiki_score: :desc).first
      species.update!(main_image_url: nil)

      get explore_path
      expect(response.body).not_to include('background-image')

      card = Nokogiri::HTML.fragment(response.body).at_css("a[href=\"#{explore_species_path(species)}\"]")
      expect(card.at_css('div.species-grid-item-photo--empty svg.fa-leaf')).not_to be_nil
    end

    it 'renders a real, lazy-loaded, sized <img> for species that have a photo' do
      species = Species.order(wiki_score: :desc).first
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
    it 'renders' do
      get explore_data_path
      expect(response).to have_http_status(:ok)
    end
  end
end
