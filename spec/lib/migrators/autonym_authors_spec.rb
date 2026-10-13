require 'rails_helper'

RSpec.describe Migrators::AutonymAuthors do
  let(:genus) { create(:genus) }
  let(:traced) { create(:species, genus_id: genus.id, rank: 'ssp', scientific_name: "#{genus.name} gautieri subsp. gautieri") }
  let(:sourced) { create(:species, genus_id: genus.id, rank: 'var', scientific_name: "#{genus.name} alpina var. alpina") }
  let(:pending) { create(:species, genus_id: genus.id, rank: 'form', scientific_name: "#{genus.name} rubra f. rubra") }
  let(:regular) { create(:species, genus_id: genus.id, rank: 'ssp', scientific_name: "#{genus.name} alpina subsp. minor") }

  before do
    [traced, sourced, pending, regular].each {|s| s.update_columns(author: 'Hack.', year: 1882) }
    SpeciesFact.record!(species: sourced, attribute_name: 'author', source: 'powo', value: 'Hack.')
    create(:record_correction, record: pending)
  end

  it 'blanks the author of an autonym and traces the removal' do
    result = described_class.run(dry_run: false)

    expect(traced.reload.author).to be_nil
    expect(traced.year).to eq(1882)
    trace = SpeciesFact.find_by(species: traced, attribute_name: 'author', source: 'legacy')
    expect(trace).to have_attributes(status: 'rejected', value: 'Hack.', notes: described_class::REASON)
    expect(result.to_h).to include(blanked: 2, legacy_traced: 1, facts_rejected: 1, skipped_pending_correction: 1)
  end

  it 'rejects the active author facts instead of adding a trace when there are some' do
    described_class.run(dry_run: false)

    fact = sourced.species_facts.for_attribute('author').sole
    expect(sourced.reload.author).to be_nil
    expect(fact.status).to eq('rejected')
    expect(fact.notes).to include(described_class::REASON)
  end

  it 'skips a record with a pending correction and a name that is not an autonym' do
    described_class.run(dry_run: false)

    expect(pending.reload.author).to eq('Hack.')
    expect(regular.reload.author).to eq('Hack.')
  end

  it 'only counts on a dry run' do
    result = described_class.run(dry_run: true)

    expect(traced.reload.author).to eq('Hack.')
    expect(result.autonyms).to eq(2)
    expect(result.blanked).to eq(0)
  end
end
