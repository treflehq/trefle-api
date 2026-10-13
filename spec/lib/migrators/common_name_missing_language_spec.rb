require 'rails_helper'

RSpec.describe Migrators::CommonNameMissingLanguage do
  let(:species) { create(:species) }
  let(:old) { Time.utc(2022, 12, 12) }
  let(:recent) { Time.utc(2026, 9, 5) }

  let!(:usda) { CommonName.create!(record: species, name: "Bliss' buckwheat", lang: nil, created_at: old, updated_at: old) }
  let!(:duplicate) { CommonName.create!(record: species, name: 'Nakedstem hawksbeard', lang: nil, created_at: old, updated_at: old) }
  let!(:english) { CommonName.create!(record: species, name: 'Nakedstem Hawksbeard', lang: 'en', created_at: recent, updated_at: recent) }
  let!(:german) { CommonName.create!(record: species, name: 'Atlas-Mohn', lang: '', created_at: recent, updated_at: recent) }
  let!(:accented) { CommonName.create!(record: species, name: 'Pavot de l’Atlas', lang: nil, created_at: old, updated_at: old) }

  it 'tags the USDA names with en and drops the ones English already has' do
    result = described_class.run(dry_run: false)

    expect(usda.reload.lang).to eq('en')
    expect(CommonName.exists?(duplicate.id)).to be(false)
    expect(english.reload.lang).to eq('en')
    expect(german.reload.lang).to eq('')
    expect(accented.reload.lang).to be_nil
    expect(result.to_h).to eq(tagged_en: 1, duplicates_removed: 1, left_recent: 1, left_non_ascii: 1)
  end

  it 'only counts on a dry run' do
    result = described_class.run(dry_run: true)

    expect(usda.reload.lang).to be_nil
    expect(CommonName.exists?(duplicate.id)).to be(true)
    expect(result.to_h).to eq(tagged_en: 1, duplicates_removed: 1, left_recent: 1, left_non_ascii: 1)
  end
end
