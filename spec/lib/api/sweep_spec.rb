require 'rails_helper'

describe Api::Sweep do

  describe '.shape_paths' do
    let(:paths) { described_class.shape_paths }

    it 'covers every collection index' do
      described_class::COLLECTIONS.each_key do |collection|
        expect(paths).to include("/api/v1/#{collection}")
      end
    end

    # The point of the shape half is that it is derived from the controllers
    # rather than hand-listed: a filter added tomorrow gets swept without anyone
    # remembering to add it here.
    it 'derives filter paths from what each controller advertises' do
      Api::V1::SpeciesController::FILTERABLE_FIELDS.each do |field|
        expect(paths.grep(%r{\A/api/v1/species\?filter\[#{Regexp.escape(field)}\]=})).not_to be_empty
      end
    end

    it 'sweeps both directions of every order key' do
      field = Api::V1::SpeciesController::ORDERABLE_FIELDS.first

      expect(paths).to include("/api/v1/species?order[#{field}]=asc")
      expect(paths).to include("/api/v1/species?order[#{field}]=desc")
    end

    it 'is bounded, so it can run on every sweep' do
      expect(paths.length).to be_between(50, 1000)
    end

    # A boolean column filtered with 'a' would blow up before the endpoint was
    # ever exercised, so the value follows the column type.
    it 'sends a value of the right type for the column being filtered' do
      expect(paths).to include('/api/v1/species?filter[duration]=1')     # integer
      expect(paths).to include('/api/v1/species?filter[edible]=true')    # boolean
      expect(paths).to include('/api/v1/species?filter[author]=a')       # string
    end
  end

  describe '.depth_paths' do
    it 'returns at most the requested slice' do
      expect(described_class.depth_paths(0, 10).length).to eq(10)
    end

    it 'advances with the cursor so consecutive runs cover new ground' do
      first = described_class.depth_paths(0, 10)
      second = described_class.depth_paths(10, 10)

      expect(second).not_to eq(first)
      expect(second & first).to be_empty
    end

    # 489k species is far more than any single run can walk, so the cursor wraps
    # rather than running off the end.
    it 'wraps around instead of returning nothing past the end' do
      huge = described_class.depth_paths(10_000_000, 5)

      expect(huge.length).to eq(5)
    end

    it 'reaches deep pages, which is where page-1 testing never looks' do
      expect(described_class.depth_paths(0, 1000)).to include('/api/v1/species?page=500')
    end
  end

end
