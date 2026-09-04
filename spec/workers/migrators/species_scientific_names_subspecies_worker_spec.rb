require 'rails_helper'

RSpec.describe Migrators::SpeciesScientificNamesSubspeciesWorker, type: :worker do
  it 'strips a repeated epithet from the varietal name when no canonical species exists yet' do
    abelia = Genus.find_by!(name: 'Abelia')
    duplicate = Species.create!(
      genus: abelia,
      rank: 'var',
      scientific_name: 'Abelia testacae var. testacae'
    )

    described_class.new.perform

    expect(duplicate.reload.scientific_name).to eq('Abelia testacae')
    expect(duplicate.rank).to eq('species')
    expect(Synonym.where(record: duplicate, name: 'Abelia testacae var. testacae').count).to eq(1)
  end
end
