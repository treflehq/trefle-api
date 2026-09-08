require 'rails_helper'

describe 'GET /api/v1/species/:id — sources[].licence', type: :request do
  let(:user) { create(:user) }
  let(:species) { create(:species) }

  before do
    powo = ForeignSource.find_by!(slug: 'powo')
    plantnet = ForeignSource.find_by!(slug: 'plantnet')
    Migrators::SourceLicences.run

    ForeignSourcesPlant.create!(species: species, foreign_source: powo, fid: 'powo-fid')
    ForeignSourcesPlant.create!(species: species, foreign_source: plantnet, fid: 'plantnet-fid')
  end

  it 'surfaces the verified upstream licence on a POWO-linked source entry' do
    get "/api/v1/species/#{species.id}", params: { token: user.token }
    sources = JSON.parse(response.body).dig('data', 'sources')

    powo_entry = sources.find {|s| s['id'] == 'powo-fid' }

    expect(response).to have_http_status(:success)
    expect(powo_entry['licence']).to eq('CC-BY-4.0')
    expect(powo_entry['licence_url']).to eq('https://creativecommons.org/licenses/by/4.0/')
  end

  it 'leaves licence NULL on a source with no verified licence' do
    get "/api/v1/species/#{species.id}", params: { token: user.token }
    sources = JSON.parse(response.body).dig('data', 'sources')

    plantnet_entry = sources.find {|s| s['id'] == 'plantnet-fid' }

    expect(plantnet_entry['licence']).to be_nil
    expect(plantnet_entry['licence_url']).to be_nil
  end
end
