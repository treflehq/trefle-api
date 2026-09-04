require 'rails_helper'

RSpec.describe Ingester::Converter::Measurement do

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

  describe 'canonical columns' do
    it 'accepts the canonical column directly' do
      result = described_class.resolve!({ average_height_cm: 250 })

      expect(result).to eq(average_height_cm: 250)
    end

    it 'accepts canonical columns in their own unit' do
      result = described_class.resolve!({
        minimum_precipitation_mm: 300,
        minimum_root_depth_cm: 45
      })

      expect(result).to eq(minimum_precipitation_mm: 300, minimum_root_depth_cm: 45)
    end

    it 'keeps zero as a legitimate canonical value' do
      # A rootless aquatic plant really does have minimum_root_depth_cm = 0
      result = described_class.resolve!({ minimum_root_depth_cm: 0 })

      expect(result).to eq(minimum_root_depth_cm: 0)
    end

    it 'prefers the explicit value/unit pair when both forms are given' do
      result = described_class.resolve!({
        average_height_value: 3, average_height_unit: 'm',
        average_height_cm: 999
      })

      expect(result).to eq(average_height_cm: 300)
    end

    it 'ignores blank canonical values' do
      expect(described_class.resolve!({ average_height_cm: nil })).to eq({})
      expect(described_class.resolve!({ average_height_cm: '' })).to eq({})
    end

    it 'still rejects a zero coming from a value/unit pair' do
      expect do
        described_class.resolve!({ average_height_value: 0, average_height_unit: 'm' })
      end.to raise_error(Ingester::Converter::Measurement::MeasurementException)
    end
  end
end
