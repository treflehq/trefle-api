require 'rails_helper'

# #438: an exact match on a common name (any language) or on the scientific
# name must rank first on the search endpoints. Before the fix every field was
# searched through its analyzed sub-field only, so "basil" scored the same for
# "Basil" and "Wild basil", and the species carrying the most common names in
# other languages lost to field-length normalisation; "corn" did not even
# bring Zea mays to page 1. Competitors below get a much higher gbif_score
# than the target so the exact-match boost is shown to beat `boost_by` too.
describe 'Search ranking (#438)', type: :request do
  let(:user) { create(:user) }

  # Suite-wide Searchkick callbacks are disabled and the model indexes through
  # a Sidekiq queue nobody drains during specs. A full reindex rebuilds the
  # index from exactly what the database holds, which also drops documents
  # left behind by earlier runs that would otherwise skew idf and ranks.
  def reindex!
    Species.reindex
    Species.searchkick_index.refresh
  end

  def names_for(path, query, **params)
    get path, params: { q: query, token: user.token, **params }
    expect(response).to have_http_status(:success)
    JSON.parse(response.body)['data'].map {|s| s['scientific_name'] }
  end

  def species_named(scientific_name, common_name:, gbif_score: nil, names: {})
    species = create(:species, scientific_name: scientific_name, common_name: common_name, gbif_score: gbif_score)
    names.each do |lang, list|
      Array(list).each {|name| CommonName.create!(record: species, name: name, lang: lang.to_s) }
    end
    species
  end

  describe 'GET /api/v1/species/search' do
    context 'with an exact English common name', search: true do
      before do
        # Many names in other languages: the length penalty that sank Ocimum basilicum
        species_named('Zzzocimum basilicum',
                      common_name: 'Basil',
                      gbif_score: 10,
                      names: { en: %w[Basil], fr: %w[Basilic], de: %w[Basilikum],
                               es: (1..30).map {|i| "Albahaca #{i}" } })
        species_named('Zzzclinopodium vulgare',
                      common_name: 'Wild basil',
                      gbif_score: 50_000,
                      names: { en: ['Wild basil', 'Basil thyme'] })
        species_named('Zzzacinos arvensis',
                      common_name: 'Basil thyme',
                      gbif_score: 20_000,
                      names: { en: ['Basil thyme'] })
        reindex!
      end

      it 'ranks the species whose common name is exactly the query first' do
        names = names_for('/api/v1/species/search', 'basil')

        expect(names.first).to eq('Zzzocimum basilicum')
        expect(names).to include('Zzzclinopodium vulgare', 'Zzzacinos arvensis')
      end

      it 'is case-insensitive' do
        expect(names_for('/api/v1/species/search', 'BASIL').first).to eq('Zzzocimum basilicum')
        expect(names_for('/api/v1/species/search', ' Basil ').first).to eq('Zzzocimum basilicum')
      end

      it 'keeps partial matches on a word of the scientific name' do
        expect(names_for('/api/v1/species/search', 'basilicum')).to eq(['Zzzocimum basilicum'])
      end

      it 'keeps partial matches on a word of a common name' do
        expect(names_for('/api/v1/species/search', 'wild')).to eq(['Zzzclinopodium vulgare'])
      end

      it 'keeps fuzzy matches on a misspelled word' do
        expect(names_for('/api/v1/species/search', 'basilicun')).to include('Zzzocimum basilicum')
      end
    end

    context 'with an exact French common name', search: true do
      before do
        species_named('Zzzsolanum lycopersicum',
                      common_name: 'Tomato',
                      gbif_score: 10,
                      names: { en: %w[Tomato], fr: %w[Tomate], de: %w[Tomate], es: %w[Tomate] })
        species_named('Zzzsolanum betaceum',
                      common_name: 'Tree tomato',
                      gbif_score: 50_000,
                      names: { en: ['Tree tomato'], fr: ['Tomate en arbre', 'Tomate arbuste'] })
        species_named('Zzzphysalis philadelphica',
                      common_name: 'Husk tomato',
                      gbif_score: 20_000,
                      names: { fr: ['Tomate verte du Mexique'] })
        reindex!
      end

      it 'ranks the species carrying that exact name in the common_names table first' do
        names = names_for('/api/v1/species/search', 'tomate')

        expect(names.first).to eq('Zzzsolanum lycopersicum')
        expect(names).to include('Zzzsolanum betaceum', 'Zzzphysalis philadelphica')
      end
    end

    context 'with an exact scientific name', search: true do
      before do
        species_named('Zzzea mays',
                      common_name: 'Maize',
                      gbif_score: 10,
                      names: { en: %w[Maize Corn], fr: %w[Maïs] })
        # Its common name repeats the whole query, which used to outscore the
        # scientific name field (common_name^10 against scientific_name^5)
        species_named('Zzzea perennis',
                      common_name: 'Zzzea mays grass',
                      gbif_score: 50_000,
                      names: { en: ['Zzzea mays grass'] })
        reindex!
      end

      it 'ranks the exact scientific name above partial matches' do
        names = names_for('/api/v1/species/search', 'Zzzea mays')

        expect(names.first).to eq('Zzzea mays')
        expect(names).to include('Zzzea perennis')
      end

      it 'still returns both species on a single word of the name' do
        expect(names_for('/api/v1/species/search', 'zzzea')).to contain_exactly('Zzzea mays', 'Zzzea perennis')
      end
    end
  end

  describe 'GET /api/v1/plants/search' do
    context 'with an exact common name', search: true do
      before do
        species_named('Zzzea mays',
                      common_name: 'Maize',
                      gbif_score: 10,
                      names: { en: %w[Maize Corn], fr: %w[Maïs], es: (1..30).map {|i| "Maíz #{i}" } })
        species_named('Zzzvalerianella locusta',
                      common_name: 'Corn salad',
                      gbif_score: 50_000,
                      names: { en: ['Corn salad', 'Lambs lettuce'] })
        species_named('Zzzagrostemma githago',
                      common_name: 'Corn cockle',
                      gbif_score: 20_000,
                      names: { en: ['Corn cockle'] })
        reindex!
      end

      it 'ranks the species whose common name is exactly the query first' do
        names = names_for('/api/v1/plants/search', 'corn')

        expect(names.first).to eq('Zzzea mays')
        expect(names).to include('Zzzvalerianella locusta', 'Zzzagrostemma githago')
      end
    end
  end
end
