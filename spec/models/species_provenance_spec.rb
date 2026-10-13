require 'rails_helper'

RSpec.describe SpeciesProvenance do
  let(:species) { Species.friendly.find('abies-alba') }

  def fact(attribute, value, source: 'try', **attrs)
    SpeciesFact.record!(species: species, attribute_name: attribute, source: source, value: value, **attrs)
  end

  def attribute(name)
    described_class.new(species.reload).attributes.find {|a| a.name == name }
  end

  it 'marks a value held by an active fact as sourced, numbers compared as numbers' do
    species.update_columns(maximum_height_cm: 500)
    fact('maximum_height_cm', 500.0)

    expect(attribute('maximum_height_cm').state).to eq(:sourced)
  end

  it 'marks a shown value no fact holds, while facts claim another, as disputed' do
    species.update_columns(maximum_height_cm: 500)
    fact('maximum_height_cm', 4200)

    expect(attribute('maximum_height_cm').state).to eq(:disputed)
  end

  it 'marks a filled field without any fact as unsourced' do
    species.update_columns(maximum_height_cm: 500)
    SpeciesFact.where(species: species, attribute_name: 'maximum_height_cm').delete_all

    expect(attribute('maximum_height_cm').state).to eq(:unsourced)
  end

  it 'marks a fact the record does not show as unshown' do
    fact('soil_ph_indicator', 6)

    expect(attribute('soil_ph_indicator').state).to eq(:unshown)
  end

  it 'matches lists whatever their order' do
    expect(described_class.same_value?('may, apr', %w[apr may])).to be(true)
    expect(described_class.same_value?('14.000000000000002', 14)).to be(true)
    expect(described_class.same_value?('jan, may', %w[apr may])).to be(false)
  end

  it 'keeps superseded facts as history' do
    fact('maximum_height_cm', 4000)
    fact('maximum_height_cm', 4200)

    expect(attribute('maximum_height_cm').history_facts.map(&:value)).to eq(['4000'])
  end
end
