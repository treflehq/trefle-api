require 'rails_helper'

RSpec.describe Checks::FactDivergence do
  let(:species) { create(:species) }

  def record(attr, value, source: 'try', n: 5, status: :active)
    SpeciesFact.record!(species: species, attribute_name: attr, source: source,
                        value: value, n_observations: n, status: status)
  end

  def warning
    RecordCorrection.find_by(record: species, warning_type: described_class.to_s)
  end

  it 'reports a column contradicted by a sourced fact' do
    species.update!(growth_rate: 'Slow')
    record('growth_rate', 'Rapid')

    described_class.run(species.id)

    expect(warning).to be_present
    expect(warning.notes).to include('growth_rate', 'Slow', 'try', 'Rapid')
  end

  it 'proposes the fact value as the correction' do
    species.update!(growth_rate: 'Slow')
    record('growth_rate', 'Rapid')

    described_class.run(species.id)

    expect(JSON.parse(warning.correction_json)).to eq('growth_rate' => 'Rapid')
  end

  it 'stays quiet when the fact agrees with the column' do
    species.update!(growth_rate: 'Rapid')
    record('growth_rate', 'Rapid')

    described_class.run(species.id)

    expect(warning).to be_nil
  end

  it 'stays quiet when the column is empty -- that is promotion, not a conflict' do
    species.update!(growth_rate: nil)
    record('growth_rate', 'Rapid')

    described_class.run(species.id)

    expect(warning).to be_nil
  end

  it 'compares a flag column in the fact serialization, not by object identity' do
    species.update!(flower_color: %i[yellow white])
    record('flower_color', 'yellow|white')

    described_class.run(species.id)

    expect(warning).to be_nil
  end

  it 'reports a flag column that genuinely differs' do
    species.update!(flower_color: %i[yellow])
    record('flower_color', 'red|blue')

    described_class.run(species.id)

    expect(warning).to be_present
  end

  it 'only compares the strongest source when several disagree' do
    species.update!(growth_rate: 'Rapid')
    record('growth_rate', 'Rapid', source: 'try')
    record('growth_rate', 'Slow', source: 'powo')

    described_class.run(species.id)

    expect(warning).to be_nil
  end

  it 'ignores facts that are not active' do
    species.update!(growth_rate: 'Slow')
    record('growth_rate', 'Rapid', status: :rejected)

    described_class.run(species.id)

    expect(warning).to be_nil
  end

  it 'ignores an attribute outside the traits.yml contract' do
    species.update!(protein_potential: 'Low')
    record('protein_potential', 'High')

    described_class.run(species.id)

    expect(warning).to be_nil
  end

  it 'is part of the checks run for every species' do
    expect(Checks.run_all(species.id).length).to eq(5)
  end
end
