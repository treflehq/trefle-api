require 'rails_helper'

RSpec.describe Ingester::Converter::CommonName do

  it 'Can process a good name' do

    hash = {
      scientific_name: 'Aiphanes grandis',
      rank: 'species',
      author: 'Borchs. & Balslev',
      genus: 'Aiphanes',
      status: 'accepted',
      common_name: 'one|two|three'
    }

    result = Ingester::Converter::CommonName.resolve!(hash)
    expect(result[:common_names_attributes]).to include(
      { name: 'one' },
      { name: 'two' },
      { name: 'three' }
    )
  end

  it 'Dont crash when no name' do
    result = Ingester::Converter::CommonName.resolve!({})
    expect(result).to eq({})
  end

  describe 'the common_name column' do
    it 'sets the column to the first name given' do
      result = described_class.resolve!({ common_name: 'Stinging nettle|Ortie' })

      expect(result[:common_name]).to eq('Stinging nettle')
    end

    it 'reaches the column through the ingester' do
      species = create(:species)

      Ingester::Species.new({ source_gbif: 'g', common_name: 'Stinging nettle' },
                            species_id: species.id).ingest!

      # Was silently dropped before: no converter wrote the column, so a source
      # could send the key and see nothing happen.
      expect(species.reload.common_name).to eq('Stinging nettle')
    end

    it 'is arbitrated like any other claimed value' do
      species = create(:species)

      Ingester::Species.new({ source_powo: 'p', common_name: 'Common nettle' },
                            species_id: species.id, source: 'powo').ingest!
      Ingester::Species.new({ source_gbif: 'g', common_name: 'Something else' },
                            species_id: species.id, source: 'gbif').ingest!

      expect(species.reload.common_name).to eq('Common nettle')
    end
  end

end
