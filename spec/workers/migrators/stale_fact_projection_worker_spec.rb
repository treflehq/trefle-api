require 'rails_helper'

RSpec.describe Migrators::StaleFactProjectionWorker do

  it 'journals the run with its scope and report, as a dry run by default' do
    expect { described_class.new.perform }.to change(DataRun, :count).by(1)

    run = DataRun.last
    expect(run.runnable).to eq('Migrators::StaleFactProjectionWorker')
    expect(run.dry_run).to be(true)
    expect(run.status).to eq('completed')
    expect(run.arguments).to include('attribute' => 'bloom_months', 'source' => 'try', 'dataset' => 174)
    expect(run.report).to include('candidates' => 0, 'reset' => 0)
  end

  it 'records a real run as one' do
    described_class.new.perform(false)

    expect(DataRun.last.dry_run).to be(false)
  end

end
