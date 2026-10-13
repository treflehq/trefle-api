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

  describe '.resolve!' do
    it 'finds a zone by its slug, whatever the case' do
      expect(Zone.resolve!('IRE')).to eq(country)
    end

    it 'finds a zone by its id' do
      expect(Zone.resolve!(country.id.to_s)).to eq(country)
    end

    it 'falls back to the exact name, case-insensitive' do
      expect(Zone.resolve!('northern ireland')).to eq(subregion)
    end

    it 'ignores accents in the name' do
      expect(Zone.resolve!('reunion')).to eq(Zone.find_by!(tdwg_code: 'REU'))
    end

    it 'picks the botanical country (level 3) when a region shares the name' do
      expect(Zone.where(name: 'Mongolia').pluck(:tdwg_level)).to contain_exactly(2, 3)
      expect(Zone.resolve!('Mongolia')).to eq(Zone.find_by!(tdwg_code: 'MON'))
    end

    it 'raises a not found error pointing to the name search' do
      expect { Zone.resolve!('Atlantis') }.to raise_error(ActiveRecord::RecordNotFound, /distributions\?q=Atlantis/)
    end
  end

  describe '.database_search' do
    it 'matches part of the name, case-insensitive' do
      expect(Zone.database_search('IRELAND')).to contain_exactly(country, subregion)
    end

    it 'ignores accents on both sides' do
      reunion = Zone.find_by!(tdwg_code: 'REU')
      expect(Zone.database_search('reunion')).to include(reunion)
      expect(Zone.database_search('RÉUNION')).to include(reunion)
    end

    it 'ranks the exact match first, then names starting with the query' do
      names = Zone.database_search('ireland').order(:name).map(&:name)
      expect(names).to eq(['Ireland', 'Northern Ireland'])

      names = Zone.database_search('europe').order(:name).map(&:name)
      expect(names.first).to eq('Europe') # alphabetically, Eastern Europe would come first
      expect(names).to include('Eastern Europe')
    end

    it 'escapes the LIKE wildcards' do
      expect(Zone.database_search('%')).to be_empty
    end

    it 'returns everything for a blank query' do
      expect(Zone.database_search(' ').count).to eq(Zone.count)
    end
  end

  describe '.fix_cumulative_counts' do
    let(:abies_alba) { Species.friendly.find('abies-alba') }
    let(:other_species) { Species.where.not(id: abies_alba.id).first }

    before do
      SpeciesDistribution.create!(species: abies_alba, zone: subregion, establishment: :native)
      SpeciesDistribution.create!(species: abies_alba, zone: country, establishment: :native)
      SpeciesDistribution.create!(species: other_species, zone: country, establishment: :introduced)
    end

    it 'counts the distinct species of the zone and all its descendants' do
      Zone.fix_cumulative_counts

      expect(subregion.reload.species_count_cumulative).to eq(1)
      expect(country.reload.species_count_cumulative).to eq(2) # abies alba once, not twice
      expect(region.reload.species_count_cumulative).to eq(region.all_species.distinct.count)
      expect(continent.reload.species_count_cumulative).to eq(continent.all_species.distinct.count)
      expect(continent.species_count_cumulative).to be >= 2
    end

    it 'leaves the direct species_count alone' do
      expect { Zone.fix_cumulative_counts }.not_to(change { country.reload.species_count })
    end

    it 'agrees with all_species for every zone' do
      Zone.fix_cumulative_counts

      Zone.find_each do |zone|
        expect(zone.species_count_cumulative).to eq(zone.all_species.distinct.count), zone.name
      end
    end

    it 'only writes the rows whose value changed, bumping updated_at' do
      Zone.fix_cumulative_counts
      untouched = Zone.find_by!(tdwg_code: 'ANT')
      stamp = 1.day.ago
      Zone.where(id: [untouched.id, country.id]).update_all(updated_at: stamp)
      country.update_columns(species_count_cumulative: 0)

      expect(Zone.fix_cumulative_counts).to eq(1)
      expect(country.reload.updated_at).to be > stamp
      expect(untouched.reload.updated_at).to be_within(1.second).of(stamp)
    end
  end
end
