require 'rails_helper'

RSpec.describe Checks::FactDivergence do
  let(:species) { create(:species) }

  def record(attr, value, source: 'try', observations: 5, status: :active)
    SpeciesFact.record!(species: species, attribute_name: attr, source: source,
                        value: value, n_observations: observations, status: status)
  end

  def warnings
    RecordCorrection.where(record: species, warning_type: described_class.to_s).order(:id)
  end

  def warning
    warnings.last
  end

  it 'reports a set column contradicted by a corroborated fact' do
    species.update!(flower_color: %i[yellow])
    record('flower_color', 'red, blue')

    described_class.run(species.id)

    expect(warning).to be_pending_change_status
    expect(warning.notes).to include('flower_color', 'yellow', 'no source (2022 value)', 'try', 'red, blue', '5 observations')
  end

  it 'proposes the fact value as the correction' do
    species.update!(flower_color: %i[yellow])
    record('flower_color', 'red, blue')

    described_class.run(species.id)

    expect(JSON.parse(warning.correction_json)).to eq('flower_color' => 'red, blue')
  end

  it 'files one warning per attribute, so each claim is decided on its own' do
    species.update!(flower_color: %i[yellow], bloom_months: %i[jun jul])
    record('flower_color', 'red')
    record('bloom_months', 'aug, sep')

    described_class.run(species.id)

    expect(warnings.map {|w| JSON.parse(w.correction_json) })
      .to contain_exactly({ 'flower_color' => 'red' }, { 'bloom_months' => 'aug, sep' })
  end

  it 'leaves a scalar column a stronger, corroborated source may replace to FactArbitration' do
    species.update!(growth_rate: 'Slow')
    record('growth_rate', 'Rapid')

    described_class.run(species.id)

    expect(warning).to be_nil
  end

  it 'reports a value a reviewed correction set that the column no longer holds' do
    record('growth_rate', 'Slow', source: 'community', observations: nil)
    species.update_columns(growth_rate: 'Rapid')

    described_class.run(species.id)

    expect(JSON.parse(warning.correction_json)).to eq('growth_rate' => 'Slow')
  end

  it 'stays quiet on a claim resting on fewer than three observations' do
    species.update!(flower_color: %i[yellow])
    record('flower_color', 'red', observations: 2)

    described_class.run(species.id)

    expect(warning).to be_nil
  end

  it 'stays quiet when the claimed months are contained in the column' do
    species.update!(bloom_months: %i[may jun jul])
    record('bloom_months', 'may')

    described_class.run(species.id)

    expect(warning).to be_nil
  end

  it 'reports a claim that adds to the set' do
    species.update!(flower_color: %i[yellow])
    record('flower_color', 'orange, yellow', observations: 7)

    described_class.run(species.id)

    expect(JSON.parse(warning.correction_json)).to eq('flower_color' => 'orange, yellow')
  end

  it 'stays quiet when the fact agrees with the column' do
    species.update!(flower_color: %i[yellow white])
    record('flower_color', 'white, yellow')

    described_class.run(species.id)

    expect(warning).to be_nil
  end

  it 'stays quiet when the column is empty -- that is promotion, not a conflict' do
    species.update!(flower_color: [])
    record('flower_color', 'red')

    described_class.run(species.id)

    expect(warning).to be_nil
  end

  it 'does not file again a claim a reviewer rejected' do
    species.update!(flower_color: %i[yellow])
    record('flower_color', 'red')
    described_class.run(species.id)
    warning.reject!

    expect { described_class.run(species.id) }.not_to change(warnings, :count)
  end

  it 'files a new claim after the rejection of a different one' do
    species.update!(flower_color: %i[yellow])
    record('flower_color', 'red')
    described_class.run(species.id)
    warning.reject!
    record('flower_color', 'blue')

    described_class.run(species.id)

    expect(warning).to be_pending_change_status
    expect(JSON.parse(warning.correction_json)).to eq('flower_color' => 'blue')
  end

  it 'closes a pending warning that holds several attributes and files one per attribute' do
    species.update!(flower_color: %i[yellow])
    record('flower_color', 'red')
    record('light', '7', observations: 1)
    bundle = RecordCorrection.create!(record: species, warning_type: described_class.to_s, source_type: :report,
                                      correction_json: { flower_color: 'red', light: '7' }.to_json)

    described_class.run(species.id)

    expect(bundle.reload).to be_accepted_change_status
    expect(JSON.parse(warning.correction_json)).to eq('flower_color' => 'red')
  end

  it 'closes the warning once the column agrees' do
    species.update!(flower_color: %i[yellow])
    record('flower_color', 'red')
    described_class.run(species.id)
    filed = warning

    species.update!(flower_color: %i[red])
    described_class.run(species.id)

    expect(filed.reload).not_to be_pending_change_status
  end

  it 'applies the warning it is asked to accept, not an older one of the same check' do
    species.update!(flower_color: %i[yellow])
    RecordCorrection.create!(record: species, warning_type: described_class.to_s, source_type: :report,
                             change_status: :rejected, correction_json: { flower_color: 'green' }.to_json)
    record('flower_color', 'red')
    described_class.run(species.id)

    warning.accept!(create(:user).id)

    expect(warning.reload).to be_accepted_change_status
    expect(species.reload.flower_color.to_a).to eq(%i[red])
  end

  it 'ignores facts that are not active' do
    species.update!(flower_color: %i[yellow])
    record('flower_color', 'red', status: :rejected)

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
