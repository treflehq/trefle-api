require 'rails_helper'

RSpec.describe Checks do
  let(:species) { Species.friendly.find('abies-alba') }

  describe Checks::GenusName do
    it 'creates a pending warning when the name does not match the genus' do
      species.update_columns(genus_id: Genus.find_by!(name: 'Abelia').id, genus_name: 'Abelia')

      expect { described_class.run(species.id) }.to change(RecordCorrection, :count).by(1)

      warning = RecordCorrection.find_by(warning_type: 'Checks::GenusName')
      expect(warning).to be_pending_change_status
      expect(warning.record).to eq(species)
    end

    it 'does nothing when the name matches the genus' do
      expect { described_class.run(species.id) }.not_to change(RecordCorrection, :count)
    end

    it 'resolves an outstanding warning once the data is fixed' do
      species.update_columns(genus_id: Genus.find_by!(name: 'Abelia').id, genus_name: 'Abelia')
      described_class.run(species.id)
      warning = RecordCorrection.find_by(warning_type: 'Checks::GenusName')

      species.update_columns(genus_id: Genus.find_by!(name: 'Abies').id, genus_name: 'Abies')
      described_class.run(species.id)

      expect(warning.reload).not_to be_pending_change_status
    end
  end

  describe Checks::GenusSpecies do
    it 'flags a species whose name is a bare genus for deletion' do
      species.update_columns(scientific_name: 'Abies')

      expect { described_class.run(species.id) }.to change(RecordCorrection, :count).by(1)

      warning = RecordCorrection.find_by(warning_type: 'Checks::GenusSpecies')
      expect(warning).to be_deletion_change_type
    end

    it 'ignores a well formed binomial name' do
      expect { described_class.run(species.id) }.not_to change(RecordCorrection, :count)
    end
  end

  describe Checks::ScientificNameFormat do
    it 'flags a name carrying its authorship' do
      species.update_columns(scientific_name: 'Abies alba Mill.', author: 'Mill.')

      expect { described_class.run(species.id) }.to change(RecordCorrection, :count).by(1)
    end

    it 'accepts a clean name' do
      expect { described_class.run(species.id) }.not_to change(RecordCorrection, :count)
    end
  end

  describe Checks::NameAcceptance do
    it 'flags a name unknown to both POWO and GBIF for deletion' do
      allow(Resolver::Powo).to receive(:resolve_hash).and_return(nil)
      allow(Resolver::Gbif).to receive(:resolve_hash).and_return(nil)

      expect { described_class.run(species.id) }.to change(RecordCorrection, :count).by(1)
      expect(RecordCorrection.find_by(warning_type: 'Checks::NameAcceptance')).to be_deletion_change_type
    end

    it 'suggests the accepted POWO name when it differs' do
      allow(Resolver::Powo).to receive(:resolve_hash).and_return(
        scientific_name: 'Abies nordmanniana', rank: 'species', author: 'Spach', source_powo: '123-1'
      )
      allow(Resolver::Gbif).to receive(:resolve_hash).and_return(nil)

      expect { described_class.run(species.id) }.to change(RecordCorrection, :count).by(1)

      warning = RecordCorrection.find_by(warning_type: 'Checks::NameAcceptance')
      expect(warning.notes).to include('Abies nordmanniana')
      expect(warning).to be_external_source_type
    end

    it 'does nothing when POWO agrees with our name' do
      allow(Resolver::Powo).to receive(:resolve_hash).and_return(scientific_name: 'Abies alba')

      expect { described_class.run(species.id) }.not_to change(RecordCorrection, :count)
    end
  end

  describe Checks::SpeciesDuplicates do
    it 'destroys the duplicate carrying the longer name' do
      keeper = species
      duplicate = Species.friendly.find('abies-sylvestris')
      duplicate.update_columns(token: 'duplicated-token')
      keeper.update_columns(token: 'duplicated-token')

      described_class.run(keeper.id)

      expect(Species.exists?(keeper.id)).to be(true)
      expect(Species.exists?(duplicate.id)).to be(false)
    end
  end
end
