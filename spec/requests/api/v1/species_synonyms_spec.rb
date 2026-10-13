require 'rails_helper'

# Synonyms left the list payloads and are truncated on the species detail
# (Rosa canina: 1,052 synonyms, 628 KB of a 641 KB payload). The full list
# moved to GET /api/v1/species/:id/synonyms, paginated. Both the endpoint and
# the detail also list the synonyms attached to the species' autonyms: WCVP
# records the synonyms of the typical subspecies/variety on that record
# ("Quercus robur subsp. robur" carries 333 of them, the species 5), which a
# reader of the species never saw.
RSpec.describe 'Species synonyms', type: :request do
  let(:user) { create(:user) }
  let(:genus) { create(:genus, name: 'Quercus') }

  let!(:species) { create(:species, genus: genus, scientific_name: 'Quercus robur') }
  # An autonym linked to the species the usual way...
  let!(:autonym) { create(:species, genus: genus, rank: 'ssp', main_species: species, scientific_name: 'Quercus robur subsp. robur') }
  # ...and one that is not (a few thousand autonyms in production have no main_species_id).
  let!(:unlinked_autonym) { create(:species, genus: genus, rank: 'var', scientific_name: 'Quercus robur var. robur') }
  # A non-autonym subspecies: its synonyms are its own.
  let!(:other_subspecies) { create(:species, genus: genus, rank: 'ssp', main_species: species, scientific_name: 'Quercus robur subsp. brutia') }

  before do
    Synonym.create!(record: species, name: 'Quercus pedunculata', author: 'Ehrh.')
    Synonym.create!(record: species, name: 'Quercus femina', author: 'Mill.')
    Synonym.create!(record: autonym, name: 'Quercus robur var. pedunculata')
    Synonym.create!(record: autonym, name: 'Quercus germanica', author: 'Lasch')
    Synonym.create!(record: unlinked_autonym, name: 'Quercus longaeva', author: 'Salisb.')
    Synonym.create!(record: other_subspecies, name: 'Quercus brutia', author: 'Ten.')
  end

  # Ordered by name, as the API returns them.
  let(:expected_names) { ['Quercus femina', 'Quercus germanica', 'Quercus longaeva', 'Quercus pedunculata', 'Quercus robur var. pedunculata'] }

  def get_json(path, params = {})
    get path, params: params.merge(token: user.token)
    JSON.parse(response.body)
  end

  describe 'Species#autonym_names' do
    it 'derives the four possible autonym names of a species' do
      expect(species.autonym_names).to eq(['Quercus robur subsp. robur', 'Quercus robur var. robur', 'Quercus robur f. robur', 'Quercus robur subvar. robur'])
    end

    it 'is empty for an infraspecific record or a hybrid' do
      expect(autonym.autonym_names).to eq([])
      expect(build(:species, rank: 'hybrid', scientific_name: 'Quercus × robur').autonym_names).to eq([])
    end
  end

  describe 'Species#synonyms_with_autonyms' do
    it 'lists the synonyms of the species and of its autonyms in a single query, with the record they hang on' do
      rows = nil
      queries = count_queries { rows = species.synonyms_with_autonyms.order(:name, :id).to_a }

      expect(queries).to eq(1)
      expect(rows.map(&:name)).to eq(expected_names)
      expect(rows.map(&:attached_to_name)).to eq(['Quercus robur', 'Quercus robur subsp. robur', 'Quercus robur var. robur', 'Quercus robur', 'Quercus robur subsp. robur'])
    end

    it 'leaves out the synonyms of the other subspecies' do
      expect(species.synonyms_with_autonyms.pluck(:name)).not_to include('Quercus brutia')
      expect(species.synonyms_with_autonyms_count).to eq(5)
    end
  end

  describe 'GET /api/v1/species/:species_id/synonyms' do
    it 'lists the synonyms ordered by name, each saying which record it is attached to' do
      body = get_json("/api/v1/species/#{species.slug}/synonyms")

      expect(response).to have_http_status(:ok)
      expect(body['data'].map {|s| s['name'] }).to eq(expected_names)
      expect(body['data'].map {|s| s['attached_to'] })
        .to eq(['Quercus robur', 'Quercus robur subsp. robur', 'Quercus robur var. robur', 'Quercus robur', 'Quercus robur subsp. robur'])
      expect(body['data'].first).to include('id' => Integer, 'author' => 'Mill.', 'sources' => [])
      expect(body['meta']).to include('total' => 5, 'page' => 1, 'per_page' => PerPage::DEFAULT)
      expect(body['meta']['species']).to eq('id' => species.id, 'slug' => 'quercus-robur', 'scientific_name' => 'Quercus robur')
    end

    it 'paginates with per_page and builds the links on the nested path' do
      body = get_json("/api/v1/species/#{species.slug}/synonyms", per_page: 2, page: 2)

      expect(response).to have_http_status(:ok)
      expect(body['data'].map {|s| s['name'] }).to eq(['Quercus longaeva', 'Quercus pedunculata'])
      expect(body['meta']).to include('total' => 5, 'page' => 2, 'per_page' => 2)
      expect(body['links']['self']).to start_with('/api/v1/species/quercus-robur/synonyms?')
      expect(body['links']['next']).to include('page=3').and include('per_page=2')
      expect(body['links']['last']).to include('page=3')
    end

    it 'resolves the species through a synonym slug, like the detail does' do
      body = get_json('/api/v1/species/quercus-pedunculata/synonyms')

      expect(response).to have_http_status(:ok)
      expect(body['meta']['species']['slug']).to eq('quercus-robur')
    end

    it 'answers 404 for an unknown species' do
      get_json('/api/v1/species/no-such-species/synonyms')

      expect(response).to have_http_status(:not_found)
    end

    it 'requires a token' do
      get "/api/v1/species/#{species.slug}/synonyms"

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'GET /api/v1/species/:id (detail)' do
    it 'embeds the synonyms of the species and of its autonyms, with the count and a link to the full list' do
      body = get_json("/api/v1/species/#{species.slug}")

      expect(response).to have_http_status(:ok)
      data = body['data']
      expect(data['synonyms'].map {|s| s['name'] }).to eq(expected_names)
      expect(data['synonyms'].map {|s| s['attached_to'] }).to include('Quercus robur', 'Quercus robur subsp. robur')
      expect(data['synonyms_count']).to eq(5)
      expect(body['meta']['synonyms_count']).to eq(5)
      expect(data['links']['synonyms']).to eq('/api/v1/species/quercus-robur/synonyms')
    end

    it 'truncates the embedded synonyms to SpeciesSerializer::SYNONYMS_LIMIT, the first ones by name, keeping the full count' do
      stub_const('SpeciesSerializer::SYNONYMS_LIMIT', 2)

      body = get_json("/api/v1/species/#{species.slug}")

      expect(body['data']['synonyms'].map {|s| s['name'] }).to eq(['Quercus femina', 'Quercus germanica'])
      expect(body['data']['synonyms_count']).to eq(5)
      expect(body['meta']['synonyms_count']).to eq(5)
    end

    it 'embeds 50 synonyms at most by default' do
      expect(SpeciesSerializer::SYNONYMS_LIMIT).to eq(50)
    end
  end

  describe 'GET /api/v1/plants/:id (detail)' do
    it 'carries the truncated synonyms on main_species only; the nested species lists have the count' do
      body = get_json("/api/v1/plants/#{species.plant.slug}")

      expect(response).to have_http_status(:ok)
      expect(body['data']['main_species']['synonyms'].map {|s| s['name'] }).to eq(expected_names)
      subspecies = body['data']['subspecies']
      expect(subspecies.map {|s| s['scientific_name'] }).to contain_exactly('Quercus robur subsp. robur', 'Quercus robur subsp. brutia')
      subspecies.each do |s|
        expect(s).not_to have_key('synonyms')
        expect(s).to have_key('synonyms_count')
      end
    end
  end

  describe 'list payloads' do
    it 'carry synonyms_count and a link instead of the synonym names (species index)' do
      body = get_json("/api/v1/genus/#{genus.slug}/species", order: { scientific_name: 'asc' })

      expect(response).to have_http_status(:ok)
      row = body['data'].find {|s| s['slug'] == 'quercus-robur' }
      expect(row).not_to have_key('synonyms')
      expect(row['synonyms_count']).to eq(2)
      expect(row['links']['synonyms']).to eq('/api/v1/species/quercus-robur/synonyms')
    end

    it 'carry synonyms_count and a link instead of the synonym names (plants index)' do
      body = get_json("/api/v1/genus/#{genus.slug}/plants")

      expect(response).to have_http_status(:ok)
      row = body['data'].find {|s| s['slug'] == 'quercus-robur' }
      expect(row).not_to have_key('synonyms')
      expect(row['synonyms_count']).to eq(2)
      expect(row['links']['synonyms']).to eq('/api/v1/species/quercus-robur/synonyms')
    end
  end
end
