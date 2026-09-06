require 'rails_helper'

RSpec.describe ApiSweepWorker do

  let(:admin) { create(:admin) }

  before do
    admin.update_columns(token: "unl-#{SecureRandom.hex(8)}")
    Sidekiq.redis {|r| r.del(described_class::CURSOR_KEY) }
  end

  it 'sweeps the whole shape, the hot records, and a slice of the depth' do
    result = described_class.new.perform(5)

    expect(result[:requested]).to eq(Api::Sweep.shape_paths.length + Api::Sweep.hot_paths.length + 5)
    expect(result[:failed]).to eq(0)
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

    described_class.new.perform(1000)

    # Going through the Rack stack rather than reproducing the key by hand is
    # the point: what gets warmed is what a request looks up.
    expect(store.exist?(key)).to be(true)
  end

  describe 'error detection' do
    it 'reports a path that returns a 500' do
      allow(Rails.application).to receive(:call).and_return([500, {}, []])

      result = described_class.new.perform(1)

      expect(result[:failed]).to eq(result[:requested])
      expect(result[:failures].first).to include(status: 500)
    end

    it 'reports a path that raises rather than letting the sweep die' do
      allow(Rails.application).to receive(:call).and_raise(ActiveRecord::StatementInvalid, 'boom')

      result = described_class.new.perform(1)

      expect(result[:failures].first[:status]).to eq('exception')
      expect(result[:failures].first[:error]).to include('boom')
    end

    it 'sends failures to Sentry, because a 500 nobody sees is no check at all' do
      allow(Rails.application).to receive(:call).and_return([500, {}, []])
      expect(Sentry).to receive(:capture_message).with(/API sweep/, hash_including(level: :error))

      described_class.new.perform(1)
    end

    # A page past the end of a collection legitimately 404s, and a 304 means the
    # cache did its job. Treating either as a failure would drown the real ones.
    it 'accepts 404 and 304 as healthy answers' do
      worker = described_class.new

      expect(worker.send(:acceptable?, 404)).to be(true)
      expect(worker.send(:acceptable?, 304)).to be(true)
      expect(worker.send(:acceptable?, 500)).to be(false)
    end
  end

  describe 'the cursor' do
    it 'advances so the next run walks different depth paths' do
      described_class.new.perform(5)
      stored = JSON.parse(Sidekiq.redis {|r| r.get(described_class::CURSOR_KEY) })

      expect(stored['position']).to eq(5)
    end

    # A cursor is worth nothing if the next run does not read it back.
    it 'resumes from where the previous run stopped rather than restarting' do
      described_class.new.perform(5)
      after_first = stored_cursor

      described_class.new.perform(5)
      after_second = stored_cursor

      expect(after_second).not_to eq(after_first)
      expect(after_second['position']).to eq(10)
    end

    it 'survives Redis being unavailable rather than skipping the sweep' do
      allow(Sidekiq).to receive(:redis).and_raise(StandardError, 'no redis')

      expect { described_class.new.perform(1) }.not_to raise_error
    end
  end

  def stored_cursor
    JSON.parse(Sidekiq.redis {|r| r.get(described_class::CURSOR_KEY) })
  end

  it 'declines to run without an unlimited token rather than burning quota' do
    admin.update_columns(token: 'spo-limited')

    expect(described_class.new.perform(1)).to be(false)
  end

end
