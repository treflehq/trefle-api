require 'rails_helper'

# Clients know a country by its name, not by its TDWG code: `?q=` searches
# the zones by name and /distributions/:id accepts the exact name as well as
# the slug. Parent zones also carry a cumulative species count (#283).
RSpec.describe 'Distributions search and cumulative counts', type: :request do
  let(:user) { create(:user) }
  let(:ireland) { Zone.find_by!(tdwg_code: 'IRE') }
  let(:northern_ireland) { Zone.find_by!(tdwg_code: 'IRE-NI') }
  let(:body) { JSON.parse(response.body) }

  describe 'GET /api/v1/distributions?q=' do
    it 'finds zones by part of their name, exact match first, and validates the schema' do
      get '/api/v1/distributions', params: { token: user.token, q: 'ireland' }

      expect(response).to have_http_status(:ok)
      expect(body['data'].map {|z| z['name'] }).to eq(['Ireland', 'Northern Ireland'])
      expect(body['meta']['total']).to eq(2)
      expect(body['data']).to match_response_schema(:zone)
    end

    it 'is case- and accent-insensitive' do
      get '/api/v1/distributions', params: { token: user.token, q: 'REUNION' }

      expect(body['data'].map {|z| z['slug'] }).to eq(['reu'])
    end

    it 'keeps the query in the pagination links' do
      get '/api/v1/distributions', params: { token: user.token, q: 'a', page: 2 }

      expect(response).to have_http_status(:ok)
      expect(body['links']['self']).to include('q=a')
      expect(body['links']['prev']).to include('q=a')
    end

    it 'combines with filters and ranges' do
      get '/api/v1/distributions', params: { token: user.token, q: 'ireland', filter: { tdwg_level: 4 } }

      expect(body['data'].map {|z| z['name'] }).to eq(['Northern Ireland'])
    end

    it 'returns an empty page when nothing matches' do
      get '/api/v1/distributions', params: { token: user.token, q: 'atlantis' }

      expect(response).to have_http_status(:ok)
      expect(body['data']).to eq([])
      expect(body['meta']['total']).to eq(0)
    end
  end

  describe 'GET /api/v1/distributions/:id' do
    it 'still resolves the slug' do
      get '/api/v1/distributions/ire', params: { token: user.token }

      expect(response).to have_http_status(:ok)
      expect(body['data']['id']).to eq(ireland.id)
    end

    it 'resolves the exact zone name, case-insensitive' do
      get '/api/v1/distributions/Northern%20Ireland', params: { token: user.token }

      expect(response).to have_http_status(:ok)
      expect(body['data']['id']).to eq(northern_ireland.id)
      expect(body['data']).to match_response_schema(:zone)
    end

    it 'resolves an accented name typed without accents' do
      get '/api/v1/distributions/reunion', params: { token: user.token }

      expect(response).to have_http_status(:ok)
      expect(body['data']['slug']).to eq('reu')
    end

    it 'resolves a name shared with a region to the botanical country' do
      get '/api/v1/distributions/mongolia', params: { token: user.token }

      expect(response).to have_http_status(:ok)
      expect(body['data']['slug']).to eq('mon')
      expect(body['data']['tdwg_level']).to eq(3)
    end

    it 'answers 404 with a hint to ?q= for an unknown zone' do
      get '/api/v1/distributions/atlantis', params: { token: user.token }

      expect(response).to have_http_status(:not_found)
      expect(body['error']).to be(true)
      expect(body['code']).to eq('not_found')
      expect(body['message']).to include('/api/v1/distributions?q=atlantis')
    end
  end

  describe 'nested collections' do
    it 'accept the zone name too' do
      get '/api/v1/distributions/ireland/species', params: { token: user.token }
      expect(response).to have_http_status(:ok)

      get '/api/v1/distributions/ireland/plants', params: { token: user.token }
      expect(response).to have_http_status(:ok)
    end

    it 'answer 404 with the hint for an unknown zone' do
      get '/api/v1/distributions/atlantis/species', params: { token: user.token }

      expect(response).to have_http_status(:not_found)
      expect(body['message']).to include('?q=atlantis')
    end
  end

  describe 'species_count_cumulative' do
    let(:europe) { Zone.find_by!(tdwg_code: '1') }

    before do
      species = Species.friendly.find('abies-alba')
      SpeciesDistribution.create!(species: species, zone: northern_ireland, establishment: :native)
      Zone.fix_cumulative_counts
    end

    it 'is exposed on the zone and on its parent and children' do
      get '/api/v1/distributions/ire', params: { token: user.token }

      expect(body['data']['species_count_cumulative']).to eq(ireland.all_species.distinct.count)
      expect(body['data']['parent']['species_count_cumulative']).to eq(ireland.parent.reload.species_count_cumulative)
      expect(body['data']['children'].first).to include('species_count_cumulative' => 1)
    end

    it 'counts the species of the children on the continent, where species_count does not' do
      get '/api/v1/distributions/1', params: { token: user.token }

      expect(body['data']['species_count']).to eq(europe.species_count)
      expect(body['data']['species_count_cumulative']).to be >= 1
      expect(body['data']['species_count_cumulative']).to eq(europe.reload.species_count_cumulative)
    end

    it 'matches the total of the zone species collection' do
      get '/api/v1/distributions/1/species', params: { token: user.token }

      expect(body['meta']['total']).to eq(europe.reload.species_count_cumulative)
    end

    it 'can be ordered and ranged on' do
      get '/api/v1/distributions', params: { token: user.token, order: { species_count_cumulative: :desc }, range: { species_count_cumulative: '1,' } }

      expect(response).to have_http_status(:ok)
      counts = body['data'].map {|z| z['species_count_cumulative'] }
      expect(counts).to all(be >= 1)
      expect(counts).to eq(counts.sort.reverse)
    end
  end
end
