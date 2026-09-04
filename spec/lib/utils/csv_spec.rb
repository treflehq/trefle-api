require 'rails_helper'

RSpec.describe Utils::Csv do
  describe '.array_to_csv' do
    it 'returns false for an empty array' do
      expect(described_class.array_to_csv([])).to be(false)
    end

    it 'renders a tab-separated CSV string from an array of hashes' do
      csv = described_class.array_to_csv([{ name: 'Abies alba', rank: 'species' }])

      expect(csv).to eq("name\trank\nAbies alba\tspecies\n")
    end

    it 'writes to the given filename when one is provided' do
      Dir.mktmpdir do |dir|
        path = File.join(dir, 'export.csv')

        described_class.array_to_csv([{ name: 'Abies alba' }], path)

        expect(File.read(path)).to eq("name\nAbies alba\n")
      end
    end
  end

  describe '.csv_to_array' do
    it 'reads a CSV file back into an array of symbol-keyed hashes' do
      Dir.mktmpdir do |dir|
        path = File.join(dir, 'import.csv')
        File.write(path, "Scientific Name\tRank\nAbies alba\tspecies\n")

        result = described_class.csv_to_array(path)

        # header names go through .parameterize, which hyphenates rather than
        # underscores ("Scientific Name" => :"scientific-name")
        expect(result).to eq([{ "scientific-name": 'Abies alba', rank: 'species' }])
      end
    end
  end
end
