require 'rails_helper'

RSpec.describe 'Species data sources page', type: :request do
  let(:species) { Species.friendly.find('abies-alba') }

  it 'lists each value with what the sources say' do
    species.update_columns(maximum_height_cm: 5000)
    SpeciesFact.record!(species: species, attribute_name: 'maximum_height_cm', source: 'try', value: 5000.0,
                        evidence_type: :measured, n_observations: 12, notes: 'TRY 7.0 datasets 25')

    get sources_explore_species_path(species)

    expect(response).to have_http_status(:ok)
    row = Nokogiri::HTML(response.body).at_css('#fact-maximum_height_cm')
    expect(row.text).to include('5000 cm', 'TRY Plant Trait Database', '12 observations', 'TRY 7.0 datasets 25', 'Sourced')
  end

  it 'is linked from the species menu' do
    get explore_species_path(species)

    expect(response.body).to include(sources_explore_species_path(species))
  end
end
