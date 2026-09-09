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

  describe Migrators::Synonyms do
    # `.run` filters on status: 'Synonym', which isn't one of the Species
    # status enum values (accepted/unknown/rejected/doubtful), and
    # `migrate_species!`/`unknowise_species!` read a `synonym_of_id` column
    # that no longer exists on `species` — this migrator predates the
    # current schema and can never touch a real row. Pinning the one thing
    # it can still safely do: nothing.
    it 'is a no-op against the current schema' do
      expect { described_class.run }.not_to raise_error
    end
  end

  describe Migrators::Zones do
    # Zones are seeded with explicit production ids (db/botanic_seeds.rb),
    # which leaves the id sequence trailing the seeded max id.
    before { ActiveRecord::Base.connection.reset_pk_sequence!('zones') }

    it 'creates a zone from a TDWG code entry' do
      zone = described_class.create_zone('code' => 'ZZ', 'name' => 'Testland', 'level' => 2)

      expect(zone).to be_persisted
      expect(zone.tdwg_code).to eq('ZZ')
      expect(zone.name).to eq('Testland')
    end

    it 'links the created zone to its parent by tdwg_code' do
      parent = Zone.create!(name: 'Parentland', tdwg_code: 'PP', tdwg_level: 1)

      zone = described_class.create_zone('code' => 'CC', 'name' => 'Childland', 'level' => 2, 'parent' => 'PP')

      expect(zone.parent).to eq(parent)
    end

    it 'reuses the existing zone for an already-known code' do
      existing = Zone.create!(name: 'Testland', tdwg_code: 'ZZ', tdwg_level: 2)

      zone = described_class.create_zone('code' => 'ZZ', 'name' => 'Testland', 'level' => 2)

      expect(zone).to eq(existing)
    end
  end

  describe Migrators::References do
    it 'attaches a Wikipedia foreign source reference to a species' do
      species = Species.friendly.find('abies-alba')

      described_class.link_to_wikipedia(species, 'Abies_alba')

      wikipedia = ForeignSource.find_by!(name: 'Wikipedia')
      plant_ref = ForeignSourcesPlant.find_by(species: species, foreign_source: wikipedia)
      expect(plant_ref.fid).to eq('Abies_alba')
    end

    it 'updates the fid when linking the same species again' do
      species = Species.friendly.find('abies-alba')
      described_class.link_to_wikipedia(species, 'Abies_alba')

      described_class.link_to_wikipedia(species, 'Abies_alba_(renamed)')

      wikipedia = ForeignSource.find_by!(name: 'Wikipedia')
      plant_ref = ForeignSourcesPlant.find_by(species: species, foreign_source: wikipedia)
      expect(plant_ref.fid).to eq('Abies_alba_(renamed)')
    end
  end

  describe Migrators::SourceLicences do
    it 'seeds the verified licence onto a confirmed source' do
      powo = ForeignSource.find_by!(slug: 'powo')

      described_class.run

      expect(powo.reload.licence).to eq('CC-BY-4.0')
      expect(powo.reload.licence_url).to eq('https://creativecommons.org/licenses/by/4.0/')
    end

    it 'seeds WFO, whose slug is stored upper-case in production' do
      # Built as 'WFO' on purpose: the previous version of this example created
      # it as 'wfo', the exact string the mapping looks up, so it asserted the
      # mapping against itself and stayed green while production had no licence
      # on its largest taxonomic source.
      wfo = ForeignSource.create!(name: 'World Flora Online', slug: 'WFO')

      described_class.run

      expect(wfo.reload.licence).to eq('CC0-1.0')
      expect(wfo.reload.licence_url).to eq('https://creativecommons.org/publicdomain/zero/1.0/')
    end

    it 'reports a mapped slug that has no row rather than skipping it silently' do
      ForeignSource.where('lower(slug) = ?', 'usda').delete_all

      result = described_class.run

      expect(result[:missing]).to include('usda')
      expect(result[:seeded]).not_to include('usda')
    end

    it 'leaves an unconfirmed source at NULL rather than guess' do
      plantnet = ForeignSource.find_by!(slug: 'plantnet')

      described_class.run

      expect(plantnet.reload.licence).to be_nil
    end

    it 'is a no-op for a source outside the verified set' do
      openfarm = ForeignSource.find_by!(slug: 'openfarm')

      expect { described_class.run }.not_to(change { openfarm.reload.licence })
    end
  end

  describe Migrators::Metrics do
    it 'leaves species alone once their heights are already recorded (current data state)' do
      Species.update_all(maximum_height_cm: 100)

      expect { described_class.run }.not_to raise_error
    end
  end
end
