require 'rails_helper'

RSpec.describe Migrators::SynonymSlugsWorker do

  let(:species) { Species.friendly.find('abies-alba') }

  it 'backfills missing slugs and leaves the rest alone' do
    legacy = Synonym.create!(record: species, name: 'Abies pectinata')
    legacy.update_columns(slug: nil) # rows that predate the column
    fresh = Synonym.create!(record: species, name: 'Abies vulgaris')

    expect(described_class.new.perform).to eq(1)

    expect(legacy.reload.slug).to eq('abies-pectinata')
    expect(fresh.reload.slug).to eq('abies-vulgaris')
  end

end
