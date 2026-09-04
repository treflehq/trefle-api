# == Schema Information
#
# Table name: zones
#
#  id            :bigint           not null, primary key
#  feature       :string
#  name          :string           not null
#  slug          :string
#  species_count :integer          default(0), not null
#  tdwg_code     :string
#  tdwg_level    :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  parent_id     :integer
#

require 'rails_helper'

# The zones table is seeded from a real TDWG dataset (see db/botanic_seeds.rb)
# with production ids, so specs walk that existing hierarchy rather than
# creating new Zone rows (the id sequence trails the seeded max id).
RSpec.describe Zone, type: :model do
  let(:continent) { Zone.find_by!(name: 'Europe', tdwg_level: 1) }
  let(:region) { Zone.find_by!(name: 'Northern Europe', tdwg_level: 2) }
  let(:country) { Zone.find_by!(name: 'Ireland', tdwg_level: 3) }
  let(:subregion) { Zone.find_by!(name: 'Northern Ireland', tdwg_level: 4) }

  describe '#to_desc' do
    it 'joins the zone with its ancestors, root first' do
      expect(subregion.to_desc).to eq('Europe > Northern Europe > Ireland > Northern Ireland')
    end

    it 'is just its own name for a root zone' do
      expect(continent.to_desc).to eq('Europe')
    end
  end

  describe '#to_hierarchy' do
    it 'returns the ancestors then itself, root first' do
      expect(country.to_hierarchy).to eq([continent, region, country])
    end
  end

  describe '#parent_ids' do
    it 'returns the ancestor ids, root first' do
      expect(country.parent_ids).to eq([continent.id, region.id])
    end
  end

  describe '#parents' do
    it 'returns the ancestor zones, root first' do
      expect(country.parents).to eq([continent, region])
    end
  end

  describe '#descendents' do
    it 'returns every zone below it, excluding itself' do
      expect(country.descendents).to contain_exactly(subregion)
    end
  end

  describe '#self_and_descendents' do
    it 'includes the zone itself' do
      expect(country.self_and_descendents).to contain_exactly(country, subregion)
    end
  end

  describe '#direct_descendent_zones' do
    it 'only returns immediate children' do
      expect(country.direct_descendent_zones).to contain_exactly(subregion)
    end
  end

  describe '#brother_zones' do
    it 'returns zones sharing the same parent, including itself' do
      expect(country.brother_zones).to include(country)
      expect(country.brother_zones.map(&:parent_id).uniq).to eq([region.id])
    end
  end

  describe '.fix_global_counts' do
    it 'recomputes species_count from the actual distributions' do
      species = Species.friendly.find('abies-alba')
      SpeciesDistribution.create!(species: species, zone: subregion, establishment: :native)
      subregion.update_columns(species_count: 0)

      Zone.fix_global_counts

      expect(subregion.reload.species_count).to eq(1)
    end
  end
end
