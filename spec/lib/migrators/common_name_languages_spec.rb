require 'rails_helper'

RSpec.describe Migrators::CommonNameLanguages do
  let(:species) { create(:species) }

  before do
    CommonName.create!(record: species, name: 'Test oak', lang: 'eng')
    CommonName.create!(record: species, name: 'Test oak', lang: 'en')
    CommonName.create!(record: species, name: 'test Oak', lang: 'en')
    CommonName.create!(record: species, name: 'Chêne test', lang: 'fra')
    CommonName.create!(record: species, name: 'Carvalho teste', lang: 'pt-br')
  end

  it 'rewrites three-letter codes to two letters and drops the duplicates' do
    result = described_class.run(dry_run: false)

    names = CommonName.where(record: species).order(:id)
    expect(names.pluck(:lang)).to eq(%w[en fr pt-br])
    expect(names.first.name).to eq('Test oak')
    expect(result.normalised).to be >= 2
    expect(result.duplicates_removed).to eq(2)
  end

  it 'only counts on a dry run' do
    result = described_class.run(dry_run: true)

    expect(result.duplicates_removed).to eq(2)
    expect(CommonName.where(record: species).count).to eq(5)
    expect(CommonName.where(record: species, lang: 'eng')).to exist
  end
end
