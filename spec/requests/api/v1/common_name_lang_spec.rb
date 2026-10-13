require 'rails_helper'

# `?lang=xx` on the species and plants endpoints: `common_name` in that
# language (CommonNameLocalizer), `common_name_lang` saying which language it
# is in, and filter[common_name] matching the names of that language. A French
# client used to get English names only, `filter[common_name]=tomate` matched
# nothing, and reading `common_names.fr` took one detail call per species.
RSpec.describe 'Common names in a language (lang)', type: :request do
  let!(:user) { create(:user) }
  let(:genus) { Genus.first }

  def create_species(epithet, common_name: nil, names: {})
    species = create(:species, genus: genus, scientific_name: "#{genus.name} #{epithet}", common_name: common_name)
    names.each do |lang, list|
      list.each {|name| CommonName.create!(record: species, lang: lang, name: name) }
    end
    species
  end

  # The fixture the localizer has to get right: `fra` and `fr` rows from two
  # imports, another name recorded first, and the name both sources agree on.
  let!(:tomato) do
    names = { 'fra' => ['pomme d’amour', 'tomate'], 'fr' => ['Tomate', 'Tomate comestible'], 'en' => ['Tomato', 'Garden tomato'] }
    create_species('lycopersicoides', common_name: 'Tomato', names: names)
  end
  let!(:maize) { create_species('maydis', common_name: 'Corn', names: { 'fr' => ['Maïs'], 'deu' => ['Mais'] }) }
  let!(:english_only) { create_species('anglica', common_name: 'Englishwort') }
  let!(:nameless) { create_species('innominata') }

  def get_json(path, params = {})
    get path, params: { token: user.token }.merge(params)
    response.parsed_body
  end

  def rows_by_slug(body)
    body['data'].index_by {|row| row['slug'] }
  end

  describe 'without lang' do
    it 'keeps the English common_name and adds no key' do
      rows = rows_by_slug(get_json('/api/v1/species', per_page: 100))

      expect(rows[tomato.slug]['common_name']).to eq('Tomato')
      expect(rows[tomato.slug]).not_to have_key('common_name_lang')
    end

    it 'filters on the English name, as before' do
      body = get_json('/api/v1/species', filter: { common_name: 'tomate' })

      expect(body['data']).to be_empty
    end
  end

  describe 'on the species list' do
    it 'shows the name most sources agree on, spelled as the ISO 639-1 row has it, and its language' do
      rows = rows_by_slug(get_json('/api/v1/species', lang: 'fr', per_page: 100))

      expect(rows[tomato.slug].values_at('common_name', 'common_name_lang')).to eq(%w[Tomate fr])
      expect(rows[maize.slug].values_at('common_name', 'common_name_lang')).to eq(%w[Maïs fr])
    end

    it 'falls back to the English name, and says so' do
      rows = rows_by_slug(get_json('/api/v1/species', lang: 'fr', per_page: 100))

      expect(rows[english_only.slug].values_at('common_name', 'common_name_lang')).to eq(%w[Englishwort en])
      expect(rows[nameless.slug].values_at('common_name', 'common_name_lang')).to eq([nil, nil])
    end

    it 'reads the three-letter tags as their two-letter code (deu is de)' do
      rows = rows_by_slug(get_json('/api/v1/species', lang: 'DE', per_page: 100))

      expect(rows[maize.slug].values_at('common_name', 'common_name_lang')).to eq(%w[Mais de])
    end

    it 'keeps the English column for lang=en' do
      rows = rows_by_slug(get_json('/api/v1/species', lang: 'en', per_page: 100))

      expect(rows[tomato.slug].values_at('common_name', 'common_name_lang')).to eq(%w[Tomato en])
    end

    it 'looks the names up in one query for the page' do
      get_json('/api/v1/species', lang: 'fr')
      baseline = count_queries { get_json('/api/v1/species', lang: 'fr') }

      create_species('altera', names: { 'fr' => ['Autre'] })
      create_species('tertia', names: { 'fr' => ['Troisième'] })

      expect(count_queries { get_json('/api/v1/species', lang: 'fr') }).to eq(baseline)
    end
  end

  describe 'filter[common_name] with lang' do
    it 'matches the names of that language, ignoring case and accents' do
      expect(get_json('/api/v1/species', lang: 'fr', filter: { common_name: 'TOMATE' })['data'].pluck('slug')).to eq([tomato.slug])
      expect(get_json('/api/v1/species', lang: 'fr', filter: { common_name: 'mais' })['data'].pluck('slug')).to eq([maize.slug])
      expect(get_json('/api/v1/species', lang: 'fr', filter: { common_name: 'pomme d’amour,mais' })['data'].pluck('slug'))
        .to contain_exactly(tomato.slug, maize.slug)
    end

    it 'does not match a name of another language' do
      expect(get_json('/api/v1/species', lang: 'de', filter: { common_name: 'tomate' })['data']).to be_empty
    end

    it 'keeps or drops the species without a name in the language with null' do
      named = get_json('/api/v1/species', lang: 'fr', filter_not: { common_name: 'null' }, per_page: 100)['data'].pluck('slug')
      unnamed = get_json('/api/v1/species', lang: 'fr', filter: { common_name: 'null' }, per_page: 100)['data'].pluck('slug')

      expect(named).to include(tomato.slug, maize.slug)
      expect(named).not_to include(english_only.slug, nameless.slug)
      expect(unnamed).to include(english_only.slug, nameless.slug)
      expect(unnamed).not_to include(tomato.slug, maize.slug)
    end

    it 'counts the English column as the English name under lang=en' do
      slugs = ->(params) { get_json('/api/v1/species', { lang: 'en', per_page: 100 }.merge(params))['data'].pluck('slug') }

      expect(slugs.call(filter: { common_name: 'Englishwort' })).to eq([english_only.slug])
      expect(slugs.call(filter: { common_name: 'englishwort,tomato' })).to contain_exactly(english_only.slug, tomato.slug)
      expect(slugs.call(filter: { common_name: 'null' })).to include(nameless.slug)
      expect(slugs.call(filter: { common_name: 'null' })).not_to include(english_only.slug, tomato.slug)
      expect(slugs.call(filter_not: { common_name: 'null' })).to include(english_only.slug, tomato.slug)
      expect(slugs.call(filter_not: { common_name: 'null' })).not_to include(nameless.slug)
      expect(slugs.call(filter_not: { common_name: 'Englishwort' })).not_to include(english_only.slug)
    end

    it 'excludes a name with filter_not' do
      slugs = get_json('/api/v1/species', lang: 'fr', filter_not: { common_name: 'tomate' }, per_page: 100)['data'].pluck('slug')

      expect(slugs).to include(maize.slug)
      expect(slugs).not_to include(tomato.slug)
    end

    it 'filters the plants list the same way' do
      expect(get_json('/api/v1/plants', lang: 'fr', filter: { common_name: 'tomate' })['data'].pluck('slug')).to eq([tomato.slug])
    end
  end

  describe 'an unknown language' do
    it 'answers 400 with the accepted codes' do
      %w[xx fra f 12].each do |lang|
        body = get_json('/api/v1/species', lang: lang)

        expect(response).to have_http_status(:bad_request), lang
        expect(body['message']).to include("Unknown lang: #{lang.inspect}")
        expect(body.dig('details', 'accepted_values')).to include('en', 'fr', 'de')
      end
    end
  end

  describe 'the details' do
    it 'localizes the species detail and keeps common_names as they are' do
      body = get_json("/api/v1/species/#{tomato.slug}", lang: 'fr')

      expect(body['data'].values_at('common_name', 'common_name_lang')).to eq(%w[Tomate fr])
      expect(body.dig('data', 'common_names', 'fra')).to include('tomate')
    end

    it 'localizes the plant detail and its main species' do
      body = get_json("/api/v1/plants/#{tomato.slug}", lang: 'fr')

      expect(body['data'].values_at('common_name', 'common_name_lang')).to eq(%w[Tomate fr])
      expect(body.dig('data', 'main_species', 'common_name')).to eq('Tomate')
    end

    it 'changes nothing on the plant detail without lang' do
      body = get_json("/api/v1/plants/#{tomato.slug}")

      expect(body.dig('data', 'common_name')).to eq('Tomato')
      expect(body['data']).not_to have_key('common_name_lang')
      expect(body.dig('data', 'main_species')).not_to have_key('common_name_lang')
    end
  end

  describe 'the nested lists' do
    it 'localizes /genus/:id/species and /distributions/:id/plants' do
      zone = Zone.find_by!(name: 'Northern Ireland', tdwg_level: 4)
      SpeciesDistribution.create!(species: tomato, zone: zone, establishment: :introduced)

      genus_rows = rows_by_slug(get_json("/api/v1/genus/#{genus.slug}/species", lang: 'fr', per_page: 100))
      zone_rows = rows_by_slug(get_json("/api/v1/distributions/#{zone.slug}/plants", lang: 'fr', filter: { common_name: 'tomate' }))

      expect(genus_rows[tomato.slug]['common_name']).to eq('Tomate')
      expect(zone_rows.keys).to eq([tomato.slug])
      expect(zone_rows[tomato.slug]['common_name_lang']).to eq('fr')
    end
  end

  describe 'the serialization cache' do
    let(:memory_store) { ActiveSupport::Cache::MemoryStore.new }

    before { allow(Rails).to receive(:cache).and_return(memory_store) }

    it 'keeps the payload of each language apart, rows and detail' do
      expect(rows_by_slug(get_json('/api/v1/species', per_page: 100))[tomato.slug]['common_name']).to eq('Tomato')
      expect(rows_by_slug(get_json('/api/v1/species', lang: 'fr', per_page: 100))[tomato.slug]['common_name']).to eq('Tomate')
      expect(rows_by_slug(get_json('/api/v1/species', per_page: 100))[tomato.slug]['common_name']).to eq('Tomato')

      get_json("/api/v1/species/#{tomato.slug}")
      etag = response.headers['ETag']
      get "/api/v1/species/#{tomato.slug}", params: { token: user.token, lang: 'fr' }, headers: { 'If-None-Match' => etag }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.dig('data', 'common_name')).to eq('Tomate')
      expect(response.headers['ETag']).not_to eq(etag)
    end
  end

  describe 'on the search endpoints', search: true do
    def index_synchronously(&block)
      Searchkick.callbacks(:inline, &block)
      Species.searchkick_index.refresh
    end

    it 'localizes the names and filters on the names of the language' do
      index_synchronously { [tomato, maize, english_only].each(&:reindex) }

      all = rows_by_slug(get_json('/api/v1/species/search', q: genus.name, lang: 'fr'))
      filtered = get_json('/api/v1/species/search', q: genus.name, lang: 'fr', filter: { common_name: 'tomate' })
      plants = get_json('/api/v1/plants/search', q: genus.name, lang: 'fr', filter_not: { common_name: 'tomate' })

      expect(all[tomato.slug].values_at('common_name', 'common_name_lang')).to eq(%w[Tomate fr])
      expect(filtered['data'].pluck('slug')).to eq([tomato.slug])
      expect(plants['data'].pluck('slug')).not_to include(tomato.slug)
      expect(plants['data'].pluck('slug')).to include(maize.slug)
    end

    it 'counts the English column as the English name under lang=en' do
      index_synchronously { [tomato, english_only, nameless].each(&:reindex) }

      found = get_json('/api/v1/species/search', q: genus.name, lang: 'en', filter: { common_name: 'Englishwort' })
      unnamed = get_json('/api/v1/species/search', q: genus.name, lang: 'en', filter: { common_name: 'null' })

      expect(found['data'].pluck('slug')).to eq([english_only.slug])
      expect(unnamed['data'].pluck('slug')).to eq([nameless.slug])
    end

    it 'answers 400 rather than truncating a filter that matches too many species' do
      stub_const('CommonNameLocalization::MAX_SEARCH_FILTER_IDS', 1)

      get_json('/api/v1/species/search', q: genus.name, lang: 'fr', filter_not: { common_name: 'null' })

      expect(response).to have_http_status(:bad_request)
    end
  end
end
