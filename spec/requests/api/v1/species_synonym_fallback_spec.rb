require 'rails_helper'

# A species record merged into its accepted taxon leaves a Synonym behind;
# its slug must keep resolving so clients that stored it do not break.
RSpec.describe 'Species synonym fallback', type: :request do

  let(:user) { create(:user) }
  let(:accepted) { Species.friendly.find('abies-alba') }
  let!(:synonym) { Synonym.create!(record: accepted, name: 'Abies pectinata') }

  describe 'Species.friendly_or_synonym!' do
    it 'resolves a live slug to the species itself' do
      expect(Species.friendly_or_synonym!('abies-alba')).to eq(accepted)
    end

    it 'falls back to the accepted species through the synonym slug' do
      expect(synonym.slug).to eq('abies-pectinata')
      expect(Species.friendly_or_synonym!('abies-pectinata')).to eq(accepted)
    end

    it 'still raises on unknown slugs' do
      expect { Species.friendly_or_synonym!('no-such-species') }
        .to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  it 'serves the accepted species on /api/v1/species/:synonym_slug' do
    get '/api/v1/species/abies-pectinata', params: { token: user.token }

    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body)['data']['slug']).to eq('abies-alba')
  end

  it 'serves the accepted plant on /api/v1/plants/:synonym_slug' do
    get '/api/v1/plants/abies-pectinata', params: { token: user.token }

    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body)['data']['slug']).to eq('abies-alba')
  end

  it 'serves the provenance facts through the synonym slug' do
    SpeciesFact.record!(species: accepted, attribute_name: 'average_height_cm', source: 'powo', value: 250)

    get '/api/v1/species/abies-pectinata/facts', params: { token: user.token }

    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body)['meta']['total']).to eq(1)
  end

  it 'keeps answering 404 on unknown species' do
    get '/api/v1/species/no-such-species', params: { token: user.token }

    expect(response).to have_http_status(:not_found)
  end

  it 'renders the explore page through the synonym slug' do
    get '/explore/species/abies-pectinata'

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Abies alba')
  end

end
