require 'rails_helper'

# The Searchkick document behind /species/search and /plants/search (#438).
describe Species, 'search document' do
  describe '.search_term' do
    it 'lowercases and squishes, so index and query agree on the *_exact fields' do
      expect(Species.search_term('  Sweet   BASIL ')).to eq('sweet basil')
      expect(Species.search_term(nil)).to eq('')
    end
  end

  describe '#search_data' do
    let(:species) do
      create(:species, scientific_name: 'Zzzocimum basilicum', common_name: 'basil').tap do |s|
        CommonName.create!(record: s, name: 'Basil', lang: 'en')
        CommonName.create!(record: s, name: 'Basilic', lang: 'fr')
        CommonName.create!(record: s, name: ' Sweet  Basil', lang: 'en')
      end
    end

    it 'lists every common name, in any language, lowercased and deduplicated in common_names_exact' do
      expect(species.search_data[:common_names_exact]).to contain_exactly('basil', 'basilic', 'sweet basil')
    end

    it 'keeps the original names in common_names' do
      expect(species.search_data[:common_names]).to contain_exactly('Basil', 'Basilic', ' Sweet  Basil')
    end

    it 'lowercases the scientific name in scientific_name_exact' do
      expect(species.search_data[:scientific_name_exact]).to eq('zzzocimum basilicum')
    end

    it 'leaves common_names_exact empty when the species has no name' do
      bare = create(:species, scientific_name: 'Zzzanonymus nullus', common_name: nil)
      expect(bare.search_data[:common_names_exact]).to eq([])
    end
  end

  describe 'SEARCH_FIELDS' do
    it 'boosts the exact fields above every analyzed field' do
      boosts = Species::SEARCH_FIELDS.map {|f| (f.is_a?(Hash) ? f.keys.first : f).split('^') }
        .to_h {|name, boost| [name, boost.to_f] }

      expect(boosts['common_names_exact']).to be > boosts['common_name']
      expect(boosts['scientific_name_exact']).to be > boosts['common_name']
    end
  end
end
