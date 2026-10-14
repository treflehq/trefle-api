require 'rails_helper'

# A hidden record (Species::HIDDEN_REASONS) is not browsed, but its page
# still opens and says why it is not listed.
RSpec.describe 'Explore hidden species', type: :request do
  let(:genus) { Genus.first }
  let!(:listed) { create(:species, genus: genus, scientific_name: "#{genus.name} visibilis") }
  let!(:fossil) { create(:species, genus: genus, scientific_name: "#{genus.name} fossilis", hidden_reason: 'fossil') }

  it 'leaves it out of the browse list' do
    get explore_species_index_path(sort: 'recent')

    expect(response.body).to include(listed.scientific_name)
    expect(response.body).not_to include(fossil.scientific_name)
  end

  it 'leaves it out of its genus page' do
    get explore_genus_path(genus)

    expect(response.body).not_to include(fossil.scientific_name)
  end

  it 'opens its page with the reason' do
    get explore_species_path(fossil)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('known from fossils only')
  end
end
