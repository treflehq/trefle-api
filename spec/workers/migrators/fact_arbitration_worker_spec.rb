require 'rails_helper'

RSpec.describe Migrators::FactArbitrationWorker do
  let(:species) { create(:species) }

  before do
    species.update_columns(light: 7)
    SpeciesFact.record!(species: species, attribute_name: 'light', source: 'try', value: 3, n_observations: 2)
  end

  it 'journals a dry run without writing' do
    described_class.new.perform

    run = DataRun.find_by(runnable: described_class.name)
    expect(run).to have_attributes(dry_run: true, status: 'completed', kind: 'migration')
    expect(run.report['replaced']).to be >= 1
    expect(species.reload.light).to eq(7)
  end

  it 'journals the real run with its arguments and impact' do
    described_class.new.perform(false, 'attributes' => %w[light], 'limit' => 10)

    run = DataRun.find_by(runnable: described_class.name)
    expect(run).to have_attributes(dry_run: false, arguments: { 'attributes' => %w[light], 'limit' => 10 })
    expect(run.impact.dig('species_facts', 'delta')).to eq(1) # the legacy trace of the old value
    expect(species.reload.light).to eq(3)
  end
end
