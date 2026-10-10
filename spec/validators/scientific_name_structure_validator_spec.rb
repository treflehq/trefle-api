require 'rails_helper'

RSpec.describe ScientificNameStructureValidator do
  def valid_for?(name, rank = :species)
    species = Species.new(scientific_name: name, rank: rank)
    described_class.new(attributes: [:scientific_name]).validate_each(species, :scientific_name, name)
    species.errors[:scientific_name].empty?
  end

  it 'accepts a binomial' do
    expect(valid_for?('Rosa rugosa')).to be(true)
  end

  it 'accepts the section aggregates WCVP accepts at species rank' do
    expect(valid_for?('Taraxacum sect. Taraxacum')).to be(true)
    expect(valid_for?('Ranunculus sect. Auricomus')).to be(true)
  end

  it 'accepts a one-letter epithet' do
    expect(valid_for?('Lepanthes o')).to be(true)
  end

  it 'accepts an intergeneric hybrid written with the sign and a space before the genus' do
    expect(valid_for?('× Agropogon lutosus')).to be(true)
    expect(valid_for?('×Agropogon lutosus')).to be(true)
    expect(valid_for?('× Sorbaronia sorbifolia var. alba', :var)).to be(true)
  end

  it 'accepts the infraspecific names of a nothospecies' do
    expect(valid_for?('Rosa × odorata var. erubescens', :var)).to be(true)
    expect(valid_for?('Mentha × piperita subsp. citrata', :ssp)).to be(true)
    expect(valid_for?('Rosa ×odorata var. erubescens', :var)).to be(true)
  end

  it 'still refuses a lowercase section name, a lone genus, or a trinomial at species rank' do
    expect(valid_for?('Taraxacum sect. taraxacum')).to be(false)
    expect(valid_for?('Taraxacum')).to be(false)
    expect(valid_for?('Rosa rugosa alba')).to be(false)
  end
end
