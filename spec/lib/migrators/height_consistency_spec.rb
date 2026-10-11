require 'rails_helper'

RSpec.describe Migrators::HeightConsistency do
  let(:species) { create(:species) }

  before do
    species.update_columns(average_height_cm: 300, maximum_height_cm: 120)
    SpeciesFact.record!(species: species, attribute_name: 'maximum_height_cm', source: 'try', value: 120)
  end

  it 'empties the impossible maximum and rejects the fact behind it' do
    result = described_class.run(dry_run: false)

    expect(species.reload.maximum_height_cm).to be_nil
    expect(species.average_height_cm).to eq(300)
    fact = species.species_facts.find_by(attribute_name: 'maximum_height_cm')
    expect(fact).to be_rejected_status
    expect(fact.notes).to include('below the average height (300 cm)')
    expect(result.to_h).to include(species: 1, facts_rejected: 1)
  end

  it 'leaves a consistent record alone' do
    species.update_columns(maximum_height_cm: 400)

    described_class.run(dry_run: false)

    expect(species.reload.maximum_height_cm).to eq(400)
  end

  it 'changes nothing on a dry run' do
    described_class.run(dry_run: true)

    expect(species.reload.maximum_height_cm).to eq(120)
  end

  it 'records a rejected legacy fact when the emptied value had none' do
    legacy = create(:species)
    legacy.update_columns(average_height_cm: 300, maximum_height_cm: 120)

    result = described_class.run(dry_run: false)

    trace = SpeciesFact.find_by(species: legacy, attribute_name: 'maximum_height_cm', source: 'legacy')
    expect(legacy.reload.maximum_height_cm).to be_nil
    expect(trace).to be_rejected_status
    expect(trace.value).to eq('120')
    expect(result.legacy_traced).to be >= 1
  end
end
