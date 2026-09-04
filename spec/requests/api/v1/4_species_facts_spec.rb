require 'rails_helper'

RSpec.describe 'Species facts API', type: :request do

  let(:user) { create(:user) }
  let(:species) { Species.friendly.find('abies-alba') }

  before do
    SpeciesFact.record!(species: species, attribute_name: 'average_height_cm', source: 'powo', value: 250)
    SpeciesFact.record!(species: species, attribute_name: 'average_height_cm', source: 'wikipedia', value: 300)
  end

  it 'requires authentication' do
    get "/api/v1/species/#{species.slug}/facts"

    expect(response).to have_http_status(:unauthorized)
  end

  it 'lists the provenance facts of a species' do
    get "/api/v1/species/#{species.slug}/facts", params: { token: user.token }

    expect(response).to have_http_status(:ok)
    body = JSON.parse(response.body)
    expect(body['meta']['total']).to eq(2)

    fact = body['data'].first
    expect(fact['attribute_name']).to eq('average_height_cm')
    expect(fact['source']).to eq('powo')
    expect(fact['value']).to eq('250')
    expect(fact['unit']).to eq('cm')
    expect(fact['status']).to eq('active')
    expect(fact['evidence_type']).to eq('reported')
  end

end
