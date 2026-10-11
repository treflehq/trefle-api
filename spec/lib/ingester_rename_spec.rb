require 'rails_helper'

# A correction that changes the scientific name is a rename (#417). A crawler
# sending a different name is a disagreement, and keeps the record's name.
RSpec.describe 'Ingester renames' do

  let(:genus) { create(:genus) }
  let(:species) { create(:species, genus_id: genus.id, author: 'L.') }

  def ingest(data, **options)
    Ingester::Species.new(data, species_id: species.id, **options).ingest!
  end

  describe 'a community correction' do
    it 'renames the species, recomputes its token and keeps the old name as a synonym' do
      old_name = species.scientific_name
      new_name = "#{genus.name} renominata"

      result = ingest({ scientific_name: new_name }, source: 'community')

      expect(result[:valid]).to be(true)
      expect(species.reload.scientific_name).to eq(new_name)
      expect(species.token).to eq(Utils::ScientificName.tokenize(new_name))
      expect(species.author).to eq('L.')
      synonym = Synonym.find_by(record_type: 'Species', name: old_name)
      expect(synonym&.record).to eq(species)
    end

    it 'infers the rank from the new name when the correction gives none' do
      ingest({ scientific_name: "#{genus.name} × renominata" }, source: 'community')

      expect(species.reload.rank).to eq('hybrid')
    end

    it 'keeps the rank the correction states' do
      ingest({ scientific_name: "#{species.scientific_name} var. minor", rank: 'var' }, source: 'community')

      expect(species.reload.rank).to eq('var')
    end

    it 'moves the species under the genus of its new name' do
      other = create(:genus)

      ingest({ scientific_name: "#{other.name} translata" }, source: 'community')

      expect(species.reload.genus).to eq(other)
      expect(species.genus_name).to eq(other.name)
    end

    it 'refuses a new name whose genus we do not hold' do
      expect { ingest({ scientific_name: 'Nullumgenus ignotum' }, source: 'community') }
        .to raise_error(Ingester::IngesterException, /no genus named 'Nullumgenus'/)
      expect(species.reload.scientific_name).not_to eq('Nullumgenus ignotum')
    end

    it 'fails the save, without renaming, when another species carries the new name' do
      taken = create(:species, genus_id: genus.id)
      old_name = species.scientific_name

      result = ingest({ scientific_name: taken.scientific_name }, source: 'community')

      expect(result[:valid]).to be(false)
      expect(result[:errors].join).to match(/taken|already/)
      expect(species.reload.scientific_name).to eq(old_name)
      expect(Synonym.where(name: old_name)).not_to exist
    end
  end

  describe 'a crawler' do
    it 'keeps the record name and drops the nomenclature it sent for another one' do
      old_name = species.scientific_name

      ingest({ scientific_name: "#{genus.name} aliena", author: 'Mill.', source_gbif: '1' })

      expect(species.reload.scientific_name).to eq(old_name)
      expect(species.author).to eq('L.')
    end
  end

  describe 'RecordCorrection#accept!' do
    let(:user) { create(:user) }

    def correction(payload)
      RecordCorrection.create!(record: species, user: user, source_type: :observation,
                               change_status: :pending, correction_json: payload.to_json)
    end

    it 'applies a rename and marks the correction accepted' do
      rc = correction(scientific_name: "#{genus.name} correcta")

      rc.accept!(user.id)

      expect(rc.reload).to be_accepted_change_status
      expect(species.reload.scientific_name).to eq("#{genus.name} correcta")
    end

    it 'leaves a refused rename pending, with the reason in the notes' do
      rc = correction(scientific_name: 'Nullumgenus ignotum')

      rc.accept!(user.id)

      expect(rc.reload).to be_pending_change_status
      expect(rc.notes).to include("Unable to accept, Cannot rename to 'Nullumgenus ignotum'")
    end
  end

  describe ScientificNameStructureValidator do
    it 'reads the rank off the name structure' do
      expect(described_class.rank_for('Rosa rugosa')).to eq('species')
      expect(described_class.rank_for('Rosa × rugosa')).to eq('hybrid')
      expect(described_class.rank_for('Rosa × odorata var. erubescens')).to eq('var')
      expect(described_class.rank_for('Picea abies subsp. abies')).to eq('ssp')
      expect(described_class.rank_for('Picea abies f. abies')).to eq('form')
      expect(described_class.rank_for('× Agropogon lutosus')).to eq('species')
      expect(described_class.rank_for('Quercus robur L. 1753')).to be_nil
    end
  end
end
