require 'rails_helper'

RSpec.describe Migrators::FactPromotionWorker do

  it 'journals the promotion with its report, as a dry run by default' do
    expect { described_class.new.perform('try') }.to change(DataRun, :count).by(1)

    run = DataRun.last
    expect(run.runnable).to eq('Migrators::FactPromotionWorker')
    expect(run.dry_run).to be(true)
    expect(run.status).to eq('completed')
    expect(run.arguments).to include('source' => 'try')
    expect(run.report).to include('promoted' => 0)
  end

  it 'records a real run as one' do
    described_class.new.perform('try', false)

    expect(DataRun.last.dry_run).to be(false)
  end

end
