require 'rails_helper'

RSpec.describe Migrators::CountersWorker, type: :worker do
  it 'fixes a stale synonyms_count counter' do
    species = Species.friendly.find('abies-alba')
    species.update_columns(synonyms_count: 999)

    described_class.new.perform

    expect(species.reload.synonyms_count).to eq(species.synonyms.count)
  end

  it 'returns true' do
    expect(described_class.new.perform).to be(true)
  end
end
