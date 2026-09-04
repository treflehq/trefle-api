require 'rails_helper'

RSpec.describe Ingester::Converter::Number do

  it 'passes integers through' do
    result = described_class.resolve!({ light: 8, soil_salinity: 3 })

    expect(result).to eq(light: 8, soil_salinity: 3)
  end

  it 'parses numeric strings, whitespace included' do
    expect(described_class.resolve!({ light: ' 7 ' })).to eq(light: 7)
  end

  it 'keeps zero, which is a meaningful value on the ecological indicator scales' do
    result = described_class.resolve!({ light: 0, soil_salinity: 0 })

    expect(result).to eq(light: 0, soil_salinity: 0)
  end

  it 'drops nil' do
    expect(described_class.resolve!({ light: nil, soil_nutriments: 5 })).to eq(soil_nutriments: 5)
  end

  it 'converts the ecological indicator fields' do
    hash = {
      light: 6, atmospheric_humidity: 5, ground_humidity: 4,
      soil_nutriments: 3, soil_salinity: 0
    }

    expect(described_class.resolve!(hash)).to eq(hash)
  end

  it 'converts every number field it knows about' do
    hash = described_class::FIELDS.index_with { 1 }

    expect(described_class.resolve!(hash).keys).to match_array(described_class::FIELDS)
  end

  it 'ignores fields it does not own' do
    result = described_class.resolve!({ scientific_name: 'Abies alba', ph_minimum: 5.5, light: 4 })

    expect(result).to eq(light: 4)
  end

  it 'does not crash on an empty hash' do
    expect(described_class.resolve!({})).to eq({})
  end

  # Documents current behaviour: a non-numeric string becomes 0 rather than
  # raising. Worth knowing before routing a pipeline that may emit "unknown".
  it 'turns an unparseable string into zero' do
    expect(described_class.resolve!({ light: 'bright' })).to eq(light: 0)
  end

end
