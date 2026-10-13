require 'rails_helper'

RSpec.describe EcologicalIndicators do
  it 'covers the five indicator columns with their documented ranges' do
    expect(described_class.fields.keys).to contain_exactly('light', 'atmospheric_humidity', 'ground_humidity', 'soil_nutriments', 'soil_salinity')
    expect(described_class.field('light').values_at('min', 'max')).to eq([1, 9])
    expect(described_class.field('atmospheric_humidity').values_at('min', 'max')).to eq([1, 9])
    expect(described_class.field('ground_humidity').values_at('min', 'max')).to eq([1, 12])
    expect(described_class.field('soil_nutriments').values_at('min', 'max')).to eq([1, 9])
    expect(described_class.field('soil_salinity').values_at('min', 'max')).to eq([0, 9])
  end

  it 'labels every class of every indicator as a class, not as a measurement' do
    described_class.fields.each do |name, spec|
      expect(spec['classes'].keys).to eq((spec['min']..spec['max']).to_a), "#{name} classes do not cover its range"
      spec['classes'].each_value do |label|
        expect(label).not_to match(/lux|µg|%|Cl/), "#{name}: #{label}"
      end
    end
  end

  it 'describes a value as its class on its scale' do
    expect(described_class.describe('light', 7)).to eq('7 / 9 · half-light to light')
    expect(described_class.describe('light', 7.0)).to eq('7 / 9 · half-light to light')
    expect(described_class.describe('light', '7')).to eq('7 / 9 · half-light to light')
    expect(described_class.describe('ground_humidity', 12)).to eq('12 / 12 · deep or submerged aquatic, 1 to 3 m')
    expect(described_class.describe('soil_salinity', 0)).to eq('0 / 9 · absent from saline soils')
  end

  it 'falls back to the bare value outside the scale or for other fields' do
    expect(described_class.describe('light', 12)).to eq('12')
    expect(described_class.describe('light', 7.5)).to eq('7.5')
    expect(described_class.describe('light', nil)).to eq('')
    expect(described_class.class_label('average_height_cm', 7)).to be_nil
    expect(described_class.describe('average_height_cm', 7)).to eq('7')
  end

  it 'reminds that an indicator is a habitat class, not a tolerance' do
    expect(described_class.note).to include('not what an individual plant tolerates')
    expect(described_class.to_h.keys).to eq(%w[note indicators])
  end
end
