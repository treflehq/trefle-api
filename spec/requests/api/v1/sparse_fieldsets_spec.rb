require 'rails_helper'

# `fields=a,b` on the species and plants endpoints (SparseFieldsets): only
# those top-level keys (plus id and slug), and, on a list, any key of the
# species detail. Reading the traits of a page used to take one detail call
# per species.
RSpec.describe 'Sparse fieldsets (fields)', type: :request do
  let!(:user) { create(:user) }
  let(:genus) { Genus.first }
  let(:zone) { Zone.find_by!(name: 'Northern Ireland', tdwg_level: 4) }
  let(:powo) { ForeignSource.find_by!(slug: 'powo') }

  # A species with something in every embedded collection.
  def create_full_species(epithet)
    species = create(:species, genus: genus, scientific_name: "#{genus.name} #{epithet}", common_name: "#{epithet} tree",
                               light: 7, ph_minimum: 5.5, flower_color: %w[red], planting_spread_cm: 40)
    CommonName.create!(record: species, lang: 'fr', name: "Arbre #{epithet}")
    SpeciesDistribution.create!(species: species, zone: zone, establishment: :native)
    create(:species_image, species_id: species.id)
    ForeignSourcesPlant.create!(species: species, foreign_source: powo, fid: "powo-#{epithet}")
    species
  end

  let!(:species) { create_full_species('primus') }

  def get_json(path, params = {})
    get path, params: { token: user.token }.merge(params)
    response.parsed_body
  end

  def row(body, slug = species.slug)
    body['data'].find {|r| r['slug'] == slug }
  end

  describe 'without fields' do
    it 'keeps the light rows' do
      body = get_json('/api/v1/species', per_page: 100)

      expect(row(body).keys).to include('synonyms_count', 'links', 'family')
      expect(row(body)).not_to have_key('growth')
    end
  end

  describe 'on the lists' do
    it 'returns only the requested keys, with id and slug' do
      body = get_json('/api/v1/species', fields: 'scientific_name', per_page: 100)

      expect(response).to have_http_status(:ok)
      expect(body['data'].map {|r| r.keys.sort }.uniq).to eq([%w[id scientific_name slug]])
    end

    it 'gives the detail groups, as the detail renders them' do
      list_row = row(get_json('/api/v1/species', fields: 'growth,flower,specifications', per_page: 100))
      detail = get_json("/api/v1/species/#{species.slug}")['data']

      expect(list_row.keys).to contain_exactly('id', 'slug', 'growth', 'flower', 'specifications')
      expect(list_row.slice('growth', 'flower', 'specifications')).to eq(detail.slice('growth', 'flower', 'specifications'))
      expect(list_row.dig('growth', 'light')).to eq(7)
    end

    it 'gives the embedded collections, as the detail renders them' do
      fields = %w[common_names distribution distributions images sources]
      list_row = row(get_json('/api/v1/species', fields: fields.join(','), per_page: 20))
      detail = get_json("/api/v1/species/#{species.slug}")['data']

      expect(list_row.except('id', 'slug')).to eq(detail.slice(*fields))
      expect(list_row.dig('common_names', 'fr')).to eq(['Arbre primus'])
    end

    it 'reads synonyms_count from the counter and links like the light rows do' do
      light = row(get_json('/api/v1/species', per_page: 100))
      picked = row(get_json('/api/v1/species', fields: 'synonyms_count,links,family,genus', per_page: 100))

      expect(picked.except('id', 'slug')).to eq(light.slice('synonyms_count', 'links', 'family', 'genus'))
    end

    it 'works on /plants, the nested lists and the search endpoints alike' do
      expect(row(get_json('/api/v1/plants', fields: 'growth', per_page: 100)).keys).to contain_exactly('id', 'slug', 'growth')
      expect(row(get_json("/api/v1/genus/#{genus.slug}/species", fields: 'growth', per_page: 100)).keys).to contain_exactly('id', 'slug', 'growth')
      expect(row(get_json("/api/v1/distributions/#{zone.slug}/plants", fields: 'distribution')).keys).to contain_exactly('id', 'slug', 'distribution')
    end

    it 'keeps the query count flat as rows are added, whatever the fields' do
      fields = (SpeciesListSerializer.field_names - %w[id slug]).join(',')
      get_json('/api/v1/species', fields: fields)
      baseline = count_queries { get_json('/api/v1/species', fields: fields) }
      expect(response).to have_http_status(:ok)

      %w[secundus tertius quartus].each {|epithet| create_full_species(epithet) }

      expect(count_queries { get_json('/api/v1/species', fields: fields) }).to eq(baseline)
      expect(get_json('/api/v1/species', fields: fields, per_page: 20)['data'].size).to be >= 4
    end
  end

  describe 'validation' do
    it 'answers 400 on an unknown field, listing the valid ones' do
      body = get_json('/api/v1/species', fields: 'scientific_name,nope,growth.light')

      expect(response).to have_http_status(:bad_request)
      expect(body['message']).to start_with('Unknown fields: nope, growth.light.')
      expect(body.dig('details', 'accepted_values')).to include('growth', 'scientific_name', 'distributions')
      expect(body.dig('details', 'accepted_values')).not_to include('synonyms')
    end

    it 'keeps synonyms to the detail' do
      get_json('/api/v1/species', fields: 'synonyms')
      expect(response).to have_http_status(:bad_request)

      body = get_json("/api/v1/species/#{species.slug}", fields: 'synonyms')
      expect(response).to have_http_status(:ok)
      expect(body['data'].keys).to contain_exactly('id', 'slug', 'synonyms')
    end

    it 'answers 400 on a fields object' do
      get_json('/api/v1/species', fields: { species: 'growth' })

      expect(response).to have_http_status(:bad_request)
    end

    it 'caps the page size when a field embeds a collection per row' do
      body = get_json('/api/v1/species', fields: 'distributions', per_page: 50)

      expect(response).to have_http_status(:bad_request)
      expect(body['message']).to include('between 1 and 20 with fields=distributions')

      get_json('/api/v1/species', fields: 'growth', per_page: 100)
      expect(response).to have_http_status(:ok)
    end

    it 'ignores an empty fields' do
      expect(row(get_json('/api/v1/species', fields: '', per_page: 100))).to have_key('synonyms_count')
    end
  end

  describe 'the details' do
    it 'trims the species detail' do
      body = get_json("/api/v1/species/#{species.slug}", fields: 'growth,common_name')

      expect(body['data'].keys).to contain_exactly('id', 'slug', 'growth', 'common_name')
      expect(body['meta']).to have_key('synonyms_count')
    end

    it 'trims the plant detail, associations included' do
      body = get_json("/api/v1/plants/#{species.slug}", fields: 'common_name,species,main_species')

      expect(body['data'].keys).to contain_exactly('id', 'slug', 'common_name', 'species', 'main_species')
      expect(body.dig('data', 'main_species', 'growth', 'light')).to eq(7)

      get_json("/api/v1/plants/#{species.slug}", fields: 'growth')
      expect(response).to have_http_status(:bad_request)
    end
  end

  describe 'the serialization cache' do
    let(:memory_store) { ActiveSupport::Cache::MemoryStore.new }

    before { allow(Rails).to receive(:cache).and_return(memory_store) }

    it 'keeps each field set apart, rows and detail, whatever the order of the fields' do
      expect(row(get_json('/api/v1/species', per_page: 100))).to have_key('links')
      expect(row(get_json('/api/v1/species', fields: 'growth,flower', per_page: 100)).keys).to contain_exactly('id', 'slug', 'growth', 'flower')
      expect(row(get_json('/api/v1/species', fields: 'flower,growth', per_page: 100)).keys).to contain_exactly('id', 'slug', 'growth', 'flower')
      expect(row(get_json('/api/v1/species', per_page: 100))).to have_key('links')

      get_json("/api/v1/species/#{species.slug}")
      etag = response.headers['ETag']
      get "/api/v1/species/#{species.slug}", params: { token: user.token, fields: 'growth' }, headers: { 'If-None-Match' => etag }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['data'].keys).to contain_exactly('id', 'slug', 'growth')
      expect(response.headers['ETag']).not_to eq(etag)
    end
  end

  describe 'on the search endpoints', search: true do
    it 'returns the requested fields' do
      Searchkick.callbacks(:inline) { species.reindex }
      Species.searchkick_index.refresh

      body = get_json('/api/v1/species/search', q: genus.name, fields: 'growth,distributions')
      plants = get_json('/api/v1/plants/search', q: genus.name, fields: 'growth')

      expect(row(body).keys).to contain_exactly('id', 'slug', 'growth', 'distributions')
      expect(row(body).dig('distributions', 'native').pluck('slug')).to eq([zone.slug])
      expect(row(plants).keys).to contain_exactly('id', 'slug', 'growth')
    end
  end
end
