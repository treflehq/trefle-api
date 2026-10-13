require 'rails_helper'

RSpec.describe 'Management facts', type: :request do
  before { login_as create(:admin), scope: :user }

  let(:species) { Species.friendly.find('abies-alba') }

  it 'lists facts filtered by species and source' do
    SpeciesFact.record!(species: species, attribute_name: 'light', source: 'try', value: 7)
    SpeciesFact.record!(species: species, attribute_name: 'light', source: 'gbif', value: 3)

    get management_species_facts_path(species: species.slug, source: 'try')

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('TRY Plant Trait Database')
    expect(response.body).not_to include('>GBIF<')
  end

  it 'lists the fields whose active sources disagree' do
    SpeciesFact.record!(species: species, attribute_name: 'light', source: 'try', value: 7)
    SpeciesFact.record!(species: species, attribute_name: 'light', source: 'gbif', value: 3)
    SpeciesFact.record!(species: species, attribute_name: 'duration', source: 'try', value: 'perennial')

    get management_species_facts_path(disputed: 1)

    expect(response.body).to include('>light<')
    expect(response.body).not_to include('>duration<')
  end

  it 'shows the facts on the species page' do
    SpeciesFact.record!(species: species, attribute_name: 'light', source: 'try', value: 7)

    get management_species_path(species)

    expect(response.body).to include('id="facts"', 'fact-light')
  end

  it 'refuses non-admins' do
    logout(:user)
    login_as create(:user), scope: :user

    get management_species_facts_path

    expect(response).not_to have_http_status(:ok)
  end
end
