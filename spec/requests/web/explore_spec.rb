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
  end

  describe 'GET /explore/species/:id' do
    it 'renders a species page by slug' do
      species = Species.friendly.find('abies-alba')
      get explore_species_path(species)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Abies alba')
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
  end

  describe 'GET /explore/data' do
    it 'renders' do
      get explore_data_path
      expect(response).to have_http_status(:ok)
    end
  end
end
