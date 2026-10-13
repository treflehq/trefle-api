require 'rails_helper'

RSpec.describe DatasetVersion do
  def run!(finished_at:, dry_run: false, status: :completed, kind: 'import')
    DataRun.create!(
      runnable: 'Spec::Run', kind: kind, dry_run: dry_run, status: status,
      started_at: finished_at - 1.minute, finished_at: finished_at
    )
  end

  before { described_class.reset! }
  after { described_class.reset! }

  it 'has no version on a database with no recorded data run' do
    expect(described_class.current).to be_nil
    expect(described_class.current_version).to be_nil
  end

  it 'is the UTC date of the latest finished run' do
    run = run!(finished_at: Time.utc(2026, 10, 13, 6, 40))

    current = described_class.current
    expect(current.version).to eq('2026.10.13')
    expect(current.data_run_id).to eq(run.id)
    expect(current.released_at).to eq(run.finished_at)
  end

  it 'numbers the later runs of the same day, leaving the first one unsuffixed' do
    run!(finished_at: Time.utc(2026, 10, 11, 15, 8))
    run!(finished_at: Time.utc(2026, 10, 13, 6, 39))
    run!(finished_at: Time.utc(2026, 10, 13, 6, 40))

    expect(described_class.current_version).to eq('2026.10.13.2')
  end

  it 'ignores dry runs and runs still in progress, but counts a failed run (it may have written)' do
    run!(finished_at: Time.utc(2026, 10, 9, 11, 8))
    run!(finished_at: Time.utc(2026, 10, 12, 9, 0), dry_run: true)
    DataRun.create!(runnable: 'Spec::Run', kind: 'import', started_at: Time.utc(2026, 10, 12, 10, 0))
    expect(described_class.compute.version).to eq('2026.10.09')

    run!(finished_at: Time.utc(2026, 10, 10, 12, 0), status: :failed)
    expect(described_class.compute.version).to eq('2026.10.10')
  end

  it 'does not move when a run only read the data (an export)' do
    run!(finished_at: Time.utc(2026, 10, 9, 11, 8))
    run!(finished_at: Time.utc(2026, 10, 9, 12, 0), kind: 'export')

    expect(described_class.compute.version).to eq('2026.10.09')
  end

  it 'keeps the value for a short while in the process, until reset' do
    run!(finished_at: Time.utc(2026, 10, 9, 11, 8))
    expect(described_class.current_version).to eq('2026.10.09')

    run!(finished_at: Time.utc(2026, 10, 10, 12, 0))
    expect(described_class.current_version).to eq('2026.10.09')

    described_class.reset!
    expect(described_class.current_version).to eq('2026.10.10')
  end

  describe '.history' do
    it 'lists the versions newest first, with the same ordinals as .for_run' do
      first = run!(finished_at: Time.utc(2026, 10, 13, 6, 39))
      second = run!(finished_at: Time.utc(2026, 10, 13, 6, 40))
      older = run!(finished_at: Time.utc(2026, 10, 11, 15, 8))

      history = described_class.history
      expect(history.map {|run, _| run.id }).to eq([second.id, first.id, older.id])
      expect(history.map {|_, version| version.version }).to eq(%w[2026.10.13.2 2026.10.13 2026.10.11])
      expect(history.map {|_, version| version.version }).to eq(history.map {|run, _| described_class.for_run(run).version })
    end

    it 'computes ordinals over the whole day even when the limit cuts it' do
      run!(finished_at: Time.utc(2026, 10, 13, 6, 39))
      run!(finished_at: Time.utc(2026, 10, 13, 6, 40))

      expect(described_class.history(limit: 1).map {|_, version| version.version }).to eq(['2026.10.13.2'])
    end
  end
end
