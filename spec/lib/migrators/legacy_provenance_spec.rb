require 'rails_helper'

RSpec.describe Migrators::LegacyProvenance do
  let(:species) { create(:species) }
  let(:sourced) { create(:species) }

  before do
    species.update_columns(
      ph_minimum: 7, ph_maximum: 7.5, growth_habit: 'Forb/herb', light: 5,
      bloom_months: Species.bloom_months.to_i(%i[mar apr]), edible_part: 0, foliage_texture: nil,
      vegetable: false, leaf_retention: false, common_name: 'Test herb', observations: 'Oregon', main_image_url: 'https://example.org/habit.jpg'
    )
    sourced.update_columns(light: 6, ph_minimum: 6, ph_maximum: 8)
    SpeciesFact.record!(species: sourced, attribute_name: 'light', source: 'catminat', value: 6)
  end

  def legacy(record, field)
    SpeciesFact.find_by(species: record, attribute_name: field, source: 'legacy')
  end

  it 'traces every served value that has no fact, and nothing else' do
    result = described_class.run(dry_run: false)

    expect(legacy(species, 'growth_habit')).to have_attributes(value: 'Forb/herb', status: 'active', evidence_type: 'reported',
                                                               notes: described_class::NOTE)
    expect(legacy(species, 'light')).to have_attributes(value: '5', value_numeric: 5, unit: 'index_0_10')
    expect(legacy(species, 'bloom_months').value).to eq('mar|apr')
    expect(legacy(species, 'edible_part')).to be_nil
    expect(legacy(species, 'vegetable')).to be_nil
    expect(legacy(species, 'leaf_retention')).to be_nil
    expect(legacy(species, 'common_name')).to be_nil
    expect(legacy(species, 'observations')).to be_nil
    expect(legacy(species, 'main_image_url')).to be_nil
    expect(legacy(species, 'foliage_texture')).to be_nil
    # The seeded test dataset carries trait values of its own, so the counts are floors.
    expect(result.by_field.slice('growth_habit', 'light', 'bloom_months').values).to all(be >= 1)
    expect(result.by_field['ph_minimum']).to be >= 2
    expect(result.skipped_false_booleans.slice('vegetable', 'leaf_retention').values).to all(be >= 1)
    expect(result.facts_created).to eq(SpeciesFact.where(source: 'legacy').count)
  end

  it 'leaves a value that already has an active fact alone' do
    described_class.run(dry_run: false)

    expect(legacy(sourced, 'light')).to be_nil
    expect(sourced.species_facts.active_status.for_attribute('light').count).to eq(1)
  end

  it 'flags a Baseflor soil reaction bin as inferred, not measured' do
    result = described_class.run(dry_run: false)

    %w[ph_minimum ph_maximum].each do |field|
      expect(legacy(species, field)).to have_attributes(evidence_type: 'inferred', unit: 'ph')
      expect(legacy(species, field).notes).to include(described_class::BASEFLOR_NOTE)
      expect(legacy(sourced, field)).to have_attributes(evidence_type: 'reported', notes: described_class::NOTE)
    end
    expect(legacy(species, 'ph_maximum').value_numeric).to eq(7.5)
    expect(result.baseflor_ph_pairs).to eq(SpeciesFact.where(source: 'legacy', evidence_type: :inferred).count)
    expect(result.baseflor_ph_pairs).to be >= 2
    expect(species.reload.ph_minimum).to eq(7)
  end

  it 'only counts on a dry run' do
    result = described_class.run(dry_run: true)

    expect(SpeciesFact.where(source: 'legacy')).to be_empty
    expect(result.facts_created).to eq(result.by_field.values.sum)
    expect(result.by_field['growth_habit']).to be >= 1
  end

  it 'inserts nothing on a replay' do
    described_class.run(dry_run: false)

    expect(described_class.run(dry_run: false).facts_created).to eq(0)
    expect(SpeciesFact.where(species: species, source: 'legacy').count).to eq(5)
  end

  it 'never traces nomenclature, free text or caches of other records' do
    expect(described_class.fields).not_to include('author', 'status', 'scientific_name', 'main_image_url',
                                                  'family_common_name', 'edible', 'observations', 'common_name')
    expect(described_class.fields).to include('growth_habit', 'growth_form', 'ph_minimum', 'bloom_months')
  end
end
