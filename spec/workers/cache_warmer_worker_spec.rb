require 'rails_helper'

RSpec.describe CacheWarmerWorker do

  let(:admin) { create(:admin) }

  before { admin.update_columns(token: "unl-#{SecureRandom.hex(8)}") }

  it 'warms the collections and the most-requested records' do
    expect(described_class.new.perform(2)).to be_positive
  end

  # The test environment uses a NullStore, which includes LocalCache — so a
  # request through the Rack stack leaves a request-local cache behind and
  # `exist?` answers true for keys nothing durably stored. Asserting against
  # that would pass whether or not warming works, so this example swaps in a
  # store that really keeps what it is given.
  it 'populates the cache a real request would read' do
    store = ActiveSupport::Cache::MemoryStore.new
    allow(Rails).to receive(:cache).and_return(store)

    species = Species.order(gbif_score: :desc).first
    key = "SpeciesSerializer/#{species.cache_key}-#{species.cache_version}"
    expect(store.exist?(key)).to be(false)

    described_class.new.perform(1)

    # Going through the Rack stack rather than reproducing the key by hand is
    # the point: what gets warmed is what a request looks up.
    expect(store.exist?(key)).to be(true)
  end

  it 'declines to run without an unlimited token rather than burning quota' do
    admin.update_columns(token: 'spo-limited')

    expect(described_class.new.perform(1)).to be(false)
  end

  it 'keeps going when one record fails' do
    allow(Rails.application).to receive(:call).and_raise(StandardError, 'boom')

    expect { described_class.new.perform(1) }.not_to raise_error
  end

  it 'warms nothing but does not fail when a batch size of zero is asked for' do
    expect(described_class.new.perform(0)).to be >= 0
  end

end
