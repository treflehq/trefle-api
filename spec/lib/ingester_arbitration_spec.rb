require 'rails_helper'

RSpec.describe 'Ingester source arbitration' do

  let(:species) { create(:species) }

  def ingest(data, **options)
    Ingester::Species.new(data, species_id: species.id, **options).ingest!
  end

  it 'records an active fact with the detected source' do
    ingest({ source_gbif: '123', average_height_value: 250, average_height_unit: 'cm' })

    fact = species.species_facts.find_by(attribute_name: 'average_height_cm')
    expect(fact).not_to be_nil
    expect(fact.source).to eq('gbif')
    expect(fact.status).to eq('active')
    expect(fact.value_numeric).to eq(250)
    expect(species.reload.average_height_cm).to eq(250)
  end

  it 'supersedes the previous fact of the same source' do
    ingest({ source_gbif: '123', average_height_value: 250, average_height_unit: 'cm' })
    ingest({ source_gbif: '123', average_height_value: 300, average_height_unit: 'cm' })

    facts = species.species_facts.for_attribute('average_height_cm').order(:id)
    expect(facts.map(&:status)).to eq(%w[superseded active])
    expect(species.reload.average_height_cm).to eq(300)
  end

  it 'does not let a weaker source overwrite a stronger one, but keeps its claim' do
    ingest({ source_powo: 'p1', average_height_value: 250, average_height_unit: 'cm' })
    ingest({ source_wikipedia: 'Okra', average_height_value: 999, average_height_unit: 'cm' })

    expect(species.reload.average_height_cm).to eq(250)

    wiki_fact = species.species_facts.active_status.find_by(source: 'wikipedia', attribute_name: 'average_height_cm')
    expect(wiki_fact).not_to be_nil
    expect(wiki_fact.value_numeric).to eq(999)
    # The disagreement is visible as a conflict
    expect(wiki_fact.conflicting_facts.count).to eq(1)
  end

  it 'lets a stronger source overwrite a weaker one' do
    ingest({ source_wikipedia: 'Okra', average_height_value: 999, average_height_unit: 'cm' })
    ingest({ source_powo: 'p1', average_height_value: 250, average_height_unit: 'cm' })

    expect(species.reload.average_height_cm).to eq(250)
  end

  it 'lets a weak source fill an empty column' do
    ingest({ source_wikipedia: 'Okra', average_height_value: 180, average_height_unit: 'cm' })

    expect(species.reload.average_height_cm).to eq(180)
  end

  it 'community corrections always win' do
    ingest({ source_powo: 'p1', average_height_value: 250, average_height_unit: 'cm' })
    ingest({ average_height_value: 260, average_height_unit: 'cm' }, source: 'community')

    expect(species.reload.average_height_cm).to eq(260)
  end

  it 'rejects implausible values without assigning them' do
    ingest({ source_gbif: '123', average_height_value: 999_999, average_height_unit: 'cm' })

    expect(species.reload.average_height_cm).to be_nil
    fact = species.species_facts.find_by(attribute_name: 'average_height_cm')
    expect(fact.status).to eq('rejected')
    expect(fact.notes).to include('implausible')
  end

  it 'does not persist facts on dry run' do
    result = ingest({ source_gbif: '123', average_height_value: 250, average_height_unit: 'cm' }, dry_run: true)

    expect(result[:changes]).to include('average_height_cm' => [nil, 250])
    expect(species.species_facts.count).to eq(0)
    expect(species.reload.average_height_cm).to be_nil
  end

end
