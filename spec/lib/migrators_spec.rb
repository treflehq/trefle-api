require 'rails_helper'

RSpec.describe Migrators do
  describe Migrators::Slugs do
    it 'regenerates missing slugs' do
      species = Species.friendly.find('abies-alba')
      species.update_columns(slug: nil)

      described_class.run

      expect(species.reload.slug).to eq('abies-alba')
    end
  end

  describe Migrators::MainSpecies do
    it 'attaches an infraspecific name to its main species' do
      main = Species.friendly.find('abies-alba')
      variety = Species.create!(
        genus: main.genus,
        rank: 'var',
        scientific_name: 'Abies alba var. minora'
      )
      variety.update_columns(main_species_id: nil)

      described_class.run

      expect(variety.reload.main_species_id).to eq(main.id)
    end
  end

  describe Migrators::SynonymsDuplicates do
    it 'merges a species whose name is a registered synonym of another' do
      keeper = Species.friendly.find('abies-alba')
      synonym_name = keeper.synonyms.first.name
      duplicate = Species.create!(
        genus: keeper.genus,
        rank: 'species',
        scientific_name: synonym_name
      )

      described_class.run

      expect(Species.exists?(duplicate.id)).to be(false)
      expect(Species.exists?(keeper.id)).to be(true)
    end
  end
end
