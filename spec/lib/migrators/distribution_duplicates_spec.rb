require 'rails_helper'

RSpec.describe Migrators::DistributionDuplicates do
  let(:species) { create(:species) }
  # The seeded zones were inserted with explicit ids, so creating one would
  # collide with the sequence: use one that exists.
  let(:zone) { Zone.where(tdwg_level: 3).order(:id).last || Zone.create!(name: 'Testland', tdwg_code: 'TST', tdwg_level: 3) }

  before do
    SpeciesDistribution.create!(species: species, zone: zone, establishment: :introduced)
    SpeciesDistribution.create!(species: species, zone: zone, establishment: :native)
    SpeciesDistribution.create!(species: species, zone: zone, establishment: :native)
  end

  it 'keeps one row per zone, the strongest establishment first' do
    result = described_class.run(dry_run: false)

    rows = SpeciesDistribution.where(species: species, zone: zone)
    expect(rows.count).to eq(1)
    expect(rows.first).to be_native_establishment
    expect(result.removed).to eq(2)
    expect(zone.reload.species_count).to eq(SpeciesDistribution.where(zone: zone).count)
  end

  it 'only counts on a dry run' do
    result = described_class.run(dry_run: true)

    expect(result.duplicates).to eq(2)
    expect(SpeciesDistribution.where(species: species).count).to eq(3)
  end
end
