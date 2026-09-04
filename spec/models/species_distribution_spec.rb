# == Schema Information
#
# Table name: species_distributions
#
#  id            :integer          not null, primary key
#  zone_id       :integer          not null
#  species_id    :integer          not null
#  establishment :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_species_distributions_on_species_id  (species_id)
#  index_species_distributions_on_zone_id     (zone_id)
#

require 'rails_helper'

RSpec.describe SpeciesDistribution, type: :model do
  let(:species) { Species.friendly.find('abies-alba') }
  let(:zone) { Zone.first }

  it 'belongs to a species and a zone' do
    distribution = SpeciesDistribution.create!(species: species, zone: zone, establishment: :native)

    expect(distribution.species).to eq(species)
    expect(distribution.zone).to eq(zone)
  end

  it 'exposes the establishment enum with a suffixed predicate' do
    distribution = SpeciesDistribution.create!(species: species, zone: zone, establishment: :introduced)

    expect(distribution.introduced_establishment?).to be(true)
    expect(distribution.native_establishment?).to be(false)
  end

  it 'keeps the zone species_count in sync' do
    expect { SpeciesDistribution.create!(species: species, zone: zone, establishment: :native) }
      .to change { zone.reload.species_count }.by(1)
  end
end
