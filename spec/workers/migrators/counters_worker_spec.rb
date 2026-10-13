require 'rails_helper'

RSpec.describe Migrators::CountersWorker, type: :worker do
  it 'fixes a stale synonyms_count counter' do
    species = Species.friendly.find('abies-alba')
    species.update_columns(synonyms_count: 999)

    described_class.new.perform

    expect(species.reload.synonyms_count).to eq(species.synonyms.count)
  end

  it 'recomputes the cumulative species count of the parent zones' do
    species = Species.friendly.find('abies-alba')
    subregion = Zone.find_by!(name: 'Northern Ireland', tdwg_level: 4)
    continent = Zone.find_by!(name: 'Europe', tdwg_level: 1)
    SpeciesDistribution.create!(species: species, zone: subregion, establishment: :native)
    Zone.update_all(species_count_cumulative: 0)

    described_class.new.perform

    expect(subregion.reload.species_count_cumulative).to eq(1)
    expect(continent.reload.species_count_cumulative).to eq(continent.all_species.distinct.count)
    expect(continent.species_count_cumulative).to be >= 1
  end

  it 'returns true' do
    expect(described_class.new.perform).to be(true)
  end
end
