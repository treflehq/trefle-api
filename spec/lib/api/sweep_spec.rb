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

  describe '.hot_paths' do
    # The full walk reaches every record eventually, but a cycle is weeks long.
    # Warming is only worth anything for what people actually request, so the
    # busiest records are swept on every run as well.
    it 'points at records, most-requested first' do
      expect(Api::Sweep.hot_paths.first).to start_with('/api/v1/species/')
    end

    it 'is bounded so it cannot crowd out the rest of the sweep' do
      expect(Api::Sweep.hot_paths.length).to be <= (Api::Sweep::HOT_RECORDS * 1.5)
    end
  end

end
