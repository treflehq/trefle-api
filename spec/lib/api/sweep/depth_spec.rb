require 'rails_helper'

describe Api::Sweep::Depth do

  let(:empty) { described_class::EMPTY_CURSOR }

  it 'starts at the first index page' do
    result = described_class.paths(empty, 3)

    expect(result[:paths].first).to eq('/api/v1/species?page=1')
  end

  it 'fills the slice it was asked for' do
    expect(described_class.paths(empty, 7)[:paths].length).to eq(7)
  end

  # The whole point of the cursor: the previous implementation rotated a fixed
  # list of 625 paths, so it replayed the same sample forever and never reached
  # page 3 of species or the 601st record. A cycle must visit every path once.
  it 'visits every path exactly once per cycle' do
    size = described_class.size
    seen = []
    cursor = empty

    (size / 10.0).ceil.times do
      result = described_class.paths(cursor, 10)
      seen.concat(result[:paths])
      cursor = result[:cursor]
    end

    expect(seen.length).to be >= size
    expect(seen.first(size).uniq.length).to eq(size)
  end

  it 'crosses from one segment into the next without short-changing the slice' do
    total_index = described_class.index_page_counts.sum {|(_, pages)| pages }
    result = described_class.paths({ 'segment' => 0, 'position' => total_index - 2 }, 6)

    expect(result[:paths].length).to eq(6)
    expect(result[:paths].first).to include('?page=')
    expect(result[:paths].last).not_to include('?page=')
    expect(result[:cursor]['segment']).to eq(1)
  end

  # Records are walked by primary key rather than OFFSET: 400k rows in, `id > ?`
  # answers in 3ms where OFFSET takes 114ms.
  describe 'the record segments' do
    it 'resumes strictly after the last id it handed out' do
      first = described_class.paths({ 'segment' => 1, 'position' => nil }, 2)
      resumed = described_class.paths(first[:cursor], 2)

      expect(resumed[:paths] & first[:paths]).to be_empty
    end

    it 'reports the last id seen as the position, not an offset' do
      species = Species.order(:id).limit(2).pluck(:id).last
      result = described_class.paths({ 'segment' => 1, 'position' => nil }, 2)

      expect(result[:cursor]['position']).to eq(species)
    end

    # A slugless record would otherwise become '/api/v1/species/', which is the
    # collection index — a path the sweep would report as healthy while having
    # checked nothing.
    it 'skips a record with no slug, and tops the slice back up' do
      first = Species.order(:id).first
      Species.where(id: first.id).update_all(slug: nil)

      paths = described_class.paths({ 'segment' => 1, 'position' => first.id - 1 }, 2)[:paths]

      expect(paths).to all(match(%r{\A/api/v1/species/.+}))
      expect(paths).not_to include('/api/v1/species/')
      expect(paths.length).to eq(2)
    end
  end

  it 'wraps back to the start once every segment is exhausted' do
    exhausted = { 'segment' => described_class::SEGMENT_COUNT - 1, 'position' => 10**12 }

    result = described_class.paths(exhausted, 3)

    expect(result[:paths].first).to eq('/api/v1/species?page=1')
  end

  it 'starts a fresh cycle rather than raising on a nonsensical cursor' do
    expect(described_class.paths('not a cursor', 3)[:paths].length).to eq(3)
    expect(described_class.paths({ 'segment' => 99, 'position' => nil }, 3)[:paths].length).to eq(3)
  end

  it 'reports the size of a full cycle' do
    expect(described_class.size).to be > described_class.index_page_counts.sum {|(_, pages)| pages }
  end

end
