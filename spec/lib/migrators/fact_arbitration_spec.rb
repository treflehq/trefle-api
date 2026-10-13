require 'rails_helper'

# The case that motivated it: Fagus sylvatica served light 7 from the 2022
# import while TRY, ranked above every legacy value in config/traits.yml,
# says 3.
RSpec.describe Migrators::FactArbitration do
  let(:beech) { create(:species) }

  def fact(record, attr, value, source: 'try', observations: 3, status: :active)
    SpeciesFact.record!(species: record, attribute_name: attr, source: source, value: value,
                        n_observations: observations, status: status)
  end

  def facts(record, attr)
    SpeciesFact.where(species: record, attribute_name: attr)
  end

  context 'with a 2022 value no fact backs' do
    before do
      beech.update_columns(light: 7)
      fact(beech, 'light', 3)
    end

    it 'replaces it with the stronger fact and traces the old value as a superseded legacy fact' do
      result = described_class.run(dry_run: false)

      expect(beech.reload.light).to eq(3)
      expect(facts(beech, 'light').find_by(source: 'legacy'))
        .to have_attributes(value: '7', value_numeric: 7, status: 'superseded')
      expect(facts(beech, 'light').find_by(source: 'legacy').notes).to include('replaced by try fact')
      expect(facts(beech, 'light').find_by(source: 'try').status).to eq('active')
      expect(result).to have_attributes(replaced: 1, legacy_traces_created: 1)
      expect(result.by_pair).to include('none (2022 value, no fact) -> try (arbitrable)' => 1)
    end

    it 'writes nothing in a dry run, and reports what it would do' do
      result = nil
      expect { result = described_class.run }.not_to(change { [beech.reload.light, SpeciesFact.count] })
      expect(result.replaced).to eq(1)
    end

    it 'recomputes the completion ratio through save, not update_columns' do
      beech.update_columns(completion_ratio: 0)
      described_class.run(dry_run: false)

      expect(beech.reload.completion_ratio).to be_positive
    end

    it 'is a no-op on replay' do
      described_class.run(dry_run: false)

      expect { described_class.run(dry_run: false) }.not_to(change { [beech.reload.light, SpeciesFact.count] })
    end

    it 'leaves a fact resting on one observation alone unless told otherwise' do
      facts(beech, 'light').delete_all
      fact(beech, 'light', 3, observations: 1)

      expect(described_class.run(dry_run: false).by_verdict).to include(low_confidence: 1)
      expect(beech.reload.light).to eq(7)

      described_class.run(dry_run: false, min_observations: 1)
      expect(beech.reload.light).to eq(3)
    end

    it 'only touches the columns it is given' do
      described_class.run(dry_run: false, attributes: %w[soil_nutriments])

      expect(beech.reload.light).to eq(7)
    end

    it 'stops after limit species' do
      other = create(:species)
      other.update_columns(light: 8)
      fact(other, 'light', 4)

      described_class.run(dry_run: false, limit: 1)

      expect([beech.reload.light, other.reload.light]).to contain_exactly(3, 8)
    end
  end

  it 'supersedes the legacy fact that backed the old value' do
    beech.update_columns(soil_nutriments: 7)
    legacy = fact(beech, 'soil_nutriments', 7, source: 'legacy', observations: nil)
    fact(beech, 'soil_nutriments', 5)

    result = described_class.run(dry_run: false)

    expect(beech.reload.soil_nutriments).to eq(5)
    expect(legacy.reload.status).to eq('superseded')
    expect(result).to have_attributes(legacy_facts_superseded: 1, legacy_traces_created: 0)
  end

  it 'keeps a weaker real source active: it is still what that source says' do
    beech.update_columns(maximum_height_cm: 3000)
    pfaf = fact(beech, 'maximum_height_cm', 3000, source: 'pfaf')
    fact(beech, 'maximum_height_cm', 4000)

    described_class.run(dry_run: false)

    expect(beech.reload.maximum_height_cm).to eq(4000)
    expect(pfaf.reload.status).to eq('active')
    expect(facts(beech, 'maximum_height_cm').where(source: 'legacy')).to be_empty
  end

  it 'never touches a value a community fact stands behind' do
    beech.update_columns(light: 4)
    fact(beech, 'light', 4, source: 'community')
    fact(beech, 'light', 3)

    expect { described_class.run(dry_run: false) }.not_to(change { beech.reload.light })
  end

  it 'never lets a community fact overwrite through a bulk job either' do
    beech.update_columns(light: 4)
    fact(beech, 'light', 6, source: 'community')

    expect(described_class.run(dry_run: false).by_verdict).to include(community: 1)
    expect(beech.reload.light).to eq(4)
  end

  it 'does not let a source at or below the legacy rank replace a 2022 value' do
    beech.update_columns(light: 7)
    fact(beech, 'light', 3, source: 'catminat')

    expect(described_class.run(dry_run: false).by_verdict).to include(not_stronger: 1)
    expect(beech.reload.light).to eq(7)
  end

  # Two spellings of one source rank together (sources compare
  # case-insensitively) and may disagree: that is for a human, not for id order.
  it 'leaves a disagreement at the winning rank to a human' do
    beech.update_columns(light: 7)
    fact(beech, 'light', 3, source: 'try')
    fact(beech, 'light', 4, source: 'TRY')

    expect(described_class.run(dry_run: false).by_verdict).to include(tie_at_top: 1)
    expect(beech.reload.light).to eq(7)
  end

  it 'refuses a winning value outside the contract' do
    beech.update_columns(light: 7)
    fact(beech, 'light', 15)

    expect(described_class.run(dry_run: false).by_verdict).to include(implausible: 1)
    expect(beech.reload.light).to eq(7)
  end

  describe 'set columns' do
    before do
      beech.update_columns(duration: Species.durations.to_i(%i[perennial]))
      fact(beech, 'duration', 'annual, perennial')
    end

    it 'leaves them out of a default run' do
      expect { described_class.run(dry_run: false) }.not_to(change { beech.reload.duration.to_a })
    end

    it 'arbitrates them when named' do
      described_class.run(dry_run: false, attributes: %w[duration])

      expect(beech.reload.duration.to_a).to contain_exactly(:annual, :perennial)
      expect(facts(beech, 'duration').find_by(source: 'legacy').value).to eq('perennial')
    end
  end

  it 'skips and names a species that cannot be saved, without stopping' do
    beech.update_columns(light: 7)
    fact(beech, 'light', 3)
    allow_any_instance_of(Species).to receive(:save!) do |record|
      record.errors.add(:base, 'already broken')
      raise ActiveRecord::RecordInvalid, record
    end

    result = described_class.run(dry_run: false)

    expect(result.invalid_species).to include(beech.id => 'already broken')
    expect(beech.reload.light).to eq(7)
    expect(facts(beech, 'light').where(source: 'legacy')).to be_empty
  end
end
