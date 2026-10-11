require 'rails_helper'

# TAXONOMY.md: WCVP (source `powo`) is the authority on names and their
# authorship. Nomenclature is ranked by sources.category_priority.core; traits
# keep default_priority (2026-10 audit).
RSpec.describe 'Nomenclature source priority' do
  let(:species) { create(:species) }

  def ingest(data, source)
    Ingester::Species.new(data.merge("source_#{source}": 'ref'), species_id: species.id, source: source).ingest!
    species.reload
  end

  before { species.update_columns(author: 'Legacy.', year: 1900, light: 5) }

  it 'lets WCVP correct a legacy author and year' do
    ingest({ author: '(L.) Mill.', year: 1768 }, 'powo')

    expect(species.author).to eq('(L.) Mill.')
    expect(species.year).to eq(1768)
  end

  it 'does not let a weaker source replace a legacy author' do
    ingest({ author: 'Gbif.' }, 'gbif')

    expect(species.author).to eq('Legacy.')
  end

  it 'keeps a human correction above WCVP' do
    ingest({ author: 'Human.' }, 'community')
    ingest({ author: 'Kew.' }, 'powo')

    expect(species.author).to eq('Human.')
  end

  it 'leaves the trait order alone: powo still cannot replace a legacy trait' do
    ingest({ light: 8 }, 'powo')

    expect(species.light).to eq(5)
  end

  it 'ranks by field' do
    expect(Traits.priority_index('powo', 'author')).to be < Traits.legacy_value_priority_index('author')
    expect(Traits.priority_index('powo', 'light')).to be > Traits.legacy_value_priority_index('light')
    expect(Traits.priority_index('powo')).to eq(Traits.priority_index('powo', 'light'))
  end
end
