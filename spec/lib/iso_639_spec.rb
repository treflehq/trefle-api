require 'rails_helper'

RSpec.describe Iso639 do
  describe '.alpha2' do
    it 'reads the tags the common names are stored under as their ISO 639-1 code' do
      expect(%w[fr FR fra fre].map {|tag| described_class.alpha2(tag) }).to all(eq('fr'))
      expect(described_class.alpha2('deu')).to eq('de')
      expect(described_class.alpha2('pt-br')).to eq('pt')
      expect(described_class.alpha2('zh-hant')).to eq('zh')
      expect(described_class.alpha2('nob')).to eq('nb')
    end

    it 'gives nil for a blank tag or a language without a two-letter code' do
      expect([nil, '', ' ', 'lub-x', 'xyz', 'q'].map {|tag| described_class.alpha2(tag) }).to eq([nil, nil, nil, 'lu', nil, nil])
    end
  end
end
