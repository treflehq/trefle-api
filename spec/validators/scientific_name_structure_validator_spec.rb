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

  it 'refuses a full classification with two infraspecific ranks, whatever the rank it is filed at' do
    %i[ssp var species].each do |rank|
      species = Species.new(scientific_name: 'Dryas octopetala subsp. octopetala var. kamtschatica', rank: rank)
      described_class.new(attributes: [:scientific_name]).validate_each(species, :scientific_name, species.scientific_name)
      expect(species.errors[:scientific_name].join).to include('carries 2 infraspecific ranks; a name has one')
    end
    expect(valid_for?('Saxifraga aizoon var. aizoon subvar. brevifolia', :subvar)).to be(false)
    expect(valid_for?('Rosa canina var. dumalis f. glabra', :form)).to be(false)
  end

  it 'refuses two infraspecific ranks when the hybrid sign stands apart, at hybrid rank too' do
    ['Rosa × odorata var. x f. y', 'Rosa ×odorata var. x f. y', '× Agropogon lutosus var. x f. y'].each do |name|
      %i[hybrid var].each do |rank|
        species = Species.new(scientific_name: name, rank: rank)
        described_class.new(attributes: [:scientific_name]).validate_each(species, :scientific_name, name)
        expect(species.errors[:scientific_name].join).to include('infraspecific ranks; a name has one'), "#{name} at #{rank}"
      end
    end
  end

  it 'counts the terms, so a trailing author or a third rank does not slip through the hybrid rank either' do
    {
      'Rosa × canina var. dumalis f. glabra L.' => 2,
      'Saxifraga × aizoon var. aizoon subvar. brevifolia f. multicaulis' => 3,
      'Rosa × canina subsp. x var. y f. z (L.) Mill.' => 3
    }.each do |name, terms|
      species = Species.new(scientific_name: name, rank: :hybrid)
      described_class.new(attributes: [:scientific_name]).validate_each(species, :scientific_name, name)
      expect(species.errors[:scientific_name].join).to include("carries #{terms} infraspecific ranks"), name
    end
  end

  it 'does not take an epithet or a section for a connecting term' do
    expect(valid_for?('Taraxacum sect. Taraxacum')).to be(true)
    expect(valid_for?('Rosa canina var. dumalis', :var)).to be(true)
    expect(valid_for?('Quercus robur f. fastigiata', :form)).to be(true)
  end

  it 'still accepts the name a classification string reduces to' do
    expect(valid_for?('Dryas octopetala var. kamtschatica', :var)).to be(true)
    expect(valid_for?('Saxifraga aizoon subvar. brevifolia', :subvar)).to be(true)
  end

  it 'still refuses a lowercase section name, a lone genus, or a trinomial at species rank' do
    expect(valid_for?('Taraxacum sect. taraxacum')).to be(false)
    expect(valid_for?('Taraxacum')).to be(false)
    expect(valid_for?('Rosa rugosa alba')).to be(false)
  end
end
