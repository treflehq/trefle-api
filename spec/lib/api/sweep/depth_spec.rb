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

  # #381: the sweep enumerated every index page of every collection, but the
  # API refuses anything past WithCachedCount::MAX_PAGE_DEPTH with a 400, and
  # ApiSweep::Runner counts a 400 as a failure and reports it to Sentry. On
  # production that was ~40k guaranteed-400 paths per cycle, burying the real
  # failures the sweep exists to surface.
  describe 'the page-depth cap' do
    let(:cap) { WithCachedCount::MAX_PAGE_DEPTH }

    it 'never counts more pages for a collection than the API will serve' do
      allow(Species).to receive(:count).and_return(cap * 20 * 3) # 3x the cap

      pages = described_class.index_page_counts.to_h

      expect(pages['species']).to eq(cap)
    end

    it 'still counts every page of a collection that fits under the cap' do
      allow(Genus).to receive(:count).and_return(41)

      expect(described_class.index_page_counts.to_h['genus']).to eq(3)
    end

    it 'emits no path past the cap over a whole cycle' do
      allow(Species).to receive(:count).and_return(cap * 20 * 2)

      cursor = described_class::EMPTY_CURSOR
      deepest = 0
      20.times do
        result = described_class.paths(cursor, 200)
        result[:paths].each do |path|
          page = path[/[?&]page=(\d+)/, 1]
          deepest = [deepest, page.to_i].max if page
        end
        cursor = result[:cursor]
      end

      expect(deepest).to be <= cap
      expect(deepest).to be_positive
    end

    # The cursor is an ordinal over the concatenated page counts, so shrinking
    # those counts leaves a stored cursor pointing past the end. index_slice
    # guards on `position >= total`, which marks the segment exhausted and
    # moves on rather than erroring or skipping silently for good.
    it 'recovers from a cursor left past the end by the smaller page counts' do
      stale = { 'segment' => 0, 'position' => described_class.index_page_counts.sum {|(_, p)| p } + 10_000 }

      result = described_class.paths(stale, 5)

      expect(result[:paths]).not_to be_empty
      expect(result[:cursor]['segment']).not_to eq(0)
    end
  end

end
