require 'rails_helper'

RSpec.describe Ingester::Converter::Float do

  it 'passes floats through, truncated to two decimals' do
    result = described_class.resolve!({ ph_minimum: 5.5, ph_maximum: 7.25 })

    expect(result).to eq(ph_minimum: 5.5, ph_maximum: 7.25)
  end

  it 'truncates rather than rounds' do
    expect(described_class.resolve!({ ph_minimum: 5.999 })).to eq(ph_minimum: 5.99)
  end

  it 'parses numeric strings, whitespace included' do
    result = described_class.resolve!({ ph_minimum: ' 6.4 ', minimum_temperature_deg_c: '-12.5' })

    expect(result).to eq(ph_minimum: 6.4, minimum_temperature_deg_c: -12.5)
  end

  it 'converts integers to floats' do
    expect(described_class.resolve!({ ph_maximum: 7 })).to eq(ph_maximum: 7.0)
  end

  it 'keeps zero and negative values' do
    result = described_class.resolve!({ minimum_temperature_deg_c: 0, maximum_temperature_deg_c: -5.5 })

    expect(result).to eq(minimum_temperature_deg_c: 0.0, maximum_temperature_deg_c: -5.5)
  end

  it 'drops nil but not zero' do
    result = described_class.resolve!({ ph_minimum: nil, ph_maximum: 0 })

    expect(result).to eq(ph_maximum: 0.0)
  end

  it 'ignores fields it does not own' do
    expect(described_class.resolve!({ average_height_cm: 200, ph_minimum: 5 })).to eq(ph_minimum: 5.0)
  end

  it 'raises on a string that is not a number' do
    expect { described_class.resolve!({ ph_minimum: 'acidic' }) }.to raise_error(ArgumentError)
  end

  it 'does not crash on an empty hash' do
    expect(described_class.resolve!({})).to eq({})
  end

end
