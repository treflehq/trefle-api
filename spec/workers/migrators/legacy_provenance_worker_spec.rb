require 'rails_helper'

RSpec.describe Migrators::LegacyProvenanceWorker do
  let(:species) { create(:species) }

  before { species.update_columns(growth_habit: 'Tree') }

  it 'journals a dry run without writing a fact' do
    described_class.new.perform

    run = DataRun.find_by(runnable: described_class.name)
    expect(run).to have_attributes(dry_run: true, status: 'completed', kind: 'migration')
    expect(run.report['by_field']['growth_habit']).to be >= 1
    expect(SpeciesFact.where(source: 'legacy')).to be_empty
  end

  it 'journals the real run with its impact on the facts' do
    described_class.new.perform(false)

    run = DataRun.find_by(runnable: described_class.name)
    expect(run.dry_run).to be(false)
    expect(run.report['facts_created']).to be >= 1
    expect(run.impact.dig('active_facts', 'delta')).to eq(run.report['facts_created'])
    expect(SpeciesFact.find_by(species: species, attribute_name: 'growth_habit').source).to eq('legacy')
  end
end
