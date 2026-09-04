require 'rails_helper'

RSpec.describe Ingester::Converter::Measurement do

  describe '.resolve!' do
    it 'converts an explicit value/unit pair to the canonical unit' do
      result = described_class.resolve!({ average_height_value: 2.5, average_height_unit: 'm' })

      expect(result).to eq(average_height_cm: 250)
    end

    it 'accepts the canonical column directly' do
      result = described_class.resolve!({ average_height_cm: 250 })

      expect(result).to eq(average_height_cm: 250)
    end

    it 'accepts canonical columns in other units' do
      result = described_class.resolve!({
        minimum_precipitation_mm: 300,
        minimum_root_depth_cm: 45
      })

      expect(result).to eq(minimum_precipitation_mm: 300, minimum_root_depth_cm: 45)
    end

    it 'keeps zero as a legitimate canonical value' do
      result = described_class.resolve!({ minimum_root_depth_cm: 0 })

      expect(result).to eq(minimum_root_depth_cm: 0)
    end

    it 'prefers the explicit pair when both forms are given' do
      result = described_class.resolve!({
        average_height_value: 3, average_height_unit: 'm',
        average_height_cm: 999
      })

      expect(result).to eq(average_height_cm: 300)
    end

    it 'ignores absent and blank measurements' do
      expect(described_class.resolve!({ scientific_name: 'Abies alba' })).to eq({})
      expect(described_class.resolve!({ average_height_cm: nil })).to eq({})
      expect(described_class.resolve!({ average_height_cm: '' })).to eq({})
    end

    it 'still rejects a zero value coming from a value/unit pair' do
      expect do
        described_class.resolve!({ average_height_value: 0, average_height_unit: 'm' })
      end.to raise_error(Ingester::Converter::Measurement::MeasurementException)
    end
  end

  describe 'through the ingester' do
    let(:species) { create(:species) }

    it 'ingests a canonical measurement and records it as a fact' do
      Ingester::Species.new(
        { source_catminat: 'abc', average_height_cm: 180 },
        species_id: species.id
      ).ingest!

      expect(species.reload.average_height_cm).to eq(180)
      fact = species.species_facts.find_by(attribute_name: 'average_height_cm')
      expect(fact.source).to eq('catminat')
      expect(fact.value_numeric).to eq(180)
    end
  end

end
