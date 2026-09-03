require 'rails_helper'

RSpec.describe Utils::ScientificName do
  describe '.format_name' do
    it 'strips the authorship' do
      expect(described_class.format_name('Abies alba Mill.', 'Mill.')).to eq('Abies alba')
    end

    it 'strips parenthesised authorships' do
      expect(described_class.format_name('Abies alba (Muntz) Parker', 'Parker')).to eq('Abies alba')
    end

    it 'normalizes infraspecific qualifiers' do
      expect(described_class.format_name('Abies alba ssp minora')).to eq('Abies alba subsp. minora')
      expect(described_class.format_name('Abies alba var minora')).to eq('Abies alba var. minora')
    end

    it 'normalizes hybrid markers' do
      expect(described_class.format_name('Abies x insignis')).to eq('Abies × insignis')
    end

    it 'leaves a clean binomial untouched' do
      expect(described_class.format_name('Abies alba')).to eq('Abies alba')
    end

    it 'accepts a nil name' do
      expect(described_class.format_name(nil)).to be_nil
    end
  end

  describe '.tokenize' do
    it 'lowercases and simplifies the name' do
      expect(described_class.tokenize('Abies alba')).to eq('abies alba')
    end

    it 'drops hybrid markers' do
      expect(described_class.tokenize('Abies x insignis')).to eq('abies insignis')
    end
  end
end

RSpec.describe Utils::Merger do
  let(:keeper) { Species.friendly.find('abies-alba') }
  let(:duplicate) { Species.friendly.find('abies-sylvestris') }

  it 'moves the satellite records onto the kept species and deletes the duplicate' do
    synonym_names = duplicate.synonyms.pluck(:name)
    zone_ids = duplicate.species_distributions.pluck(:zone_id)

    described_class.new([duplicate.id], keeper.id).merge!

    expect(Species.exists?(duplicate.id)).to be(false)
    expect(keeper.reload.synonyms.pluck(:name)).to include(*synonym_names)
    expect(keeper.species_distributions.pluck(:zone_id)).to include(*zone_ids)
  end

  it 'keeps the explicitly designated species' do
    described_class.new([keeper.id, duplicate.id], keeper.id).merge!

    expect(Species.exists?(keeper.id)).to be(true)
    expect(Species.exists?(duplicate.id)).to be(false)
  end
end
