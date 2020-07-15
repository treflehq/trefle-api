require 'rails_helper'

RSpec.describe Ingester::Converter::Measurement do # rubocop:todo Metrics/BlockLength

  it 'Can process a good measurement' do

    hash = {
      scientific_name: 'Aiphanes grandis',
      rank: 'species',
      author: 'Borchs. & Balslev',
      genus: 'Aiphanes',
      status: 'accepted',
      sources: { name: 'gbif', fid: 2_738_693 },
      confidence: 98,
      average_height_value: 2100,
      average_height_unit: 'cm'
    }

    result = Ingester::Converter::Measurement.resolve!(hash)
    expect(result).to eq({
      average_height_cm: 2100
    })
  end

  it 'Can process a different unit measurement' do
    hash = {
      average_height_value: 2,
      average_height_unit: 'm'
    }

    result = Ingester::Converter::Measurement.resolve!(hash)
    expect(result).to eq({
      average_height_cm: 200
    })
  end

  it 'Can process several measurements' do
    hash = {
      average_height_value: 2,
      average_height_unit: 'm',
      minimum_root_depth_value: 120,
      minimum_root_depth_unit: 'cm'
    }

    result = Ingester::Converter::Measurement.resolve!(hash)
    expect(result).to eq({
      average_height_cm: 200,
      minimum_root_depth_cm: 120
    })
  end

  it 'Can process all measurements' do
    hash = {
      average_height_value: 2,
      average_height_unit: 'm',
      maximum_height_value: 2,
      maximum_height_unit: 'm',
      minimum_precipitation_value: 2,
      minimum_precipitation_unit: 'm',
      maximum_precipitation_value: 2,
      maximum_precipitation_unit: 'm',
      minimum_root_depth_value: 120,
      minimum_root_depth_unit: 'cm'
    }

    result = Ingester::Converter::Measurement.resolve!(hash)
    expect(result).to eq({
      average_height_cm: 200,
      maximum_height_cm: 200,
      minimum_precipitation_mm: 2000,
      maximum_precipitation_mm: 2000,
      minimum_root_depth_cm: 120
    })
  end

  it 'Dont crash when no measurements' do
    result = Ingester::Converter::Measurement.resolve!({})
    expect(result).to eq({})
  end

  it 'Crash when invalid measurements' do
    expect do
      Ingester::Converter::Measurement.resolve!(
        average_height_value: 4,
        average_height_unit: 'pikachu'
      )
    end.to raise_error(Measured::UnitError)
  end
end
