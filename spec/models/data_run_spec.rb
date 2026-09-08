require 'rails_helper'

RSpec.describe DataRun do

  describe '.track!' do
    it 'journals a successful run with its report and measured impact' do
      result = described_class.track!(runnable: 'Import::Demo', kind: 'import',
                                      arguments: { path: 'x.txt' }) do
        create(:species)
        { rows: 42 }
      end

      expect(result).to eq({ rows: 42 })
      run = described_class.sole
      expect(run).to be_completed_status
      expect(run.report).to eq({ 'rows' => 42 })
      expect(run.arguments).to eq({ 'path' => 'x.txt' })
      expect(run.impact.dig('species', 'delta')).to eq(1)
      expect(run.host).to be_present
      expect(run.duration).to be >= 0
    end

    it 'journals a failure with its partial impact, then re-raises' do
      expect do
        described_class.track!(runnable: 'Import::Demo', kind: 'import') do
          create(:species)
          raise ArgumentError, 'boom'
        end
      end.to raise_error(ArgumentError, 'boom')

      run = described_class.sole
      expect(run).to be_failed_status
      expect(run.error).to include('ArgumentError: boom')
      expect(run.impact.dig('species', 'delta')).to eq(1)
      expect(run.finished_at).to be_present
    end

    it 'flags dry runs and records zero deltas for them' do
      described_class.track!(runnable: 'Import::Demo', kind: 'import', dry_run: true) { { seen: 3 } }

      run = described_class.sole
      expect(run).to be_dry_run
      expect(run.moved_counters).to be_empty
    end
  end

end
