require 'rails_helper'

RSpec.describe Ingester::Converter::Enum do

  it 'symbolizes a textual enum value' do
    result = described_class.resolve!({ rank: 'species', status: 'accepted' })

    expect(result).to eq(rank: :species, status: :accepted)
  end

  it 'resolves a numeric value to its enum key' do
    # Species.ranks => { 'species' => 0, 'ssp' => 1, 'var' => 2, ... }
    result = described_class.resolve!({ rank: 2 })

    expect(result).to eq(rank: :var)
  end

  it 'resolves a numeric value given as a string' do
    expect(described_class.resolve!({ rank: '1' })).to eq(rank: :ssp)
  end

  it 'resolves zero, which is a valid enum key' do
    expect(described_class.resolve!({ rank: 0 })).to eq(rank: :species)
  end

  it 'raises on a numeric value outside the enum' do
    expect do
      described_class.resolve!({ rank: 99 })
    end.to raise_error(Ingester::Converter::Enum::EnumException, /Wrong value: 99/)
  end

  it 'converts every enum field it knows about' do
    hash = {
      rank: 'species', status: 'accepted', toxicity: 'low',
      foliage_texture: 'fine', ligneous_type: 'tree', soil_texture: 'argile'
    }

    expect(described_class.resolve!(hash)).to eq(
      rank: :species, status: :accepted, toxicity: :low,
      foliage_texture: :fine, ligneous_type: :tree, soil_texture: :argile
    )
  end

  it 'drops nil values' do
    expect(described_class.resolve!({ rank: 'species', toxicity: nil })).to eq(rank: :species)
  end

  it 'ignores fields it does not own' do
    expect(described_class.resolve!({ scientific_name: 'Abies alba', rank: 'species' })).to eq(rank: :species)
  end

  it 'does not crash on an empty hash' do
    expect(described_class.resolve!({})).to eq({})
  end

end
