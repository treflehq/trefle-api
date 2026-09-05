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

  it 'does not let an equally-ranked source overwrite a filled column' do
    # Two unlisted sources tie at the lowest rank: crawl order must not decide.
    ingest({ source_flora_iberica: 'a', average_height_value: 1500, average_height_unit: 'cm' })
    ingest({ source_pfaf: 'b', average_height_value: 2500, average_height_unit: 'cm' })

    expect(species.reload.average_height_cm).to eq(1500)

    values = species.species_facts.active_status.for_attribute('average_height_cm').pluck(:source, :value)
    expect(values).to contain_exactly(%w[flora_iberica 1500], %w[pfaf 2500])
  end

  it 'still lets an equally-ranked source fill an empty column' do
    ingest({ source_pfaf: 'b', average_height_value: 900, average_height_unit: 'cm' })

    expect(species.reload.average_height_cm).to eq(900)
  end

  it 'lets a ranked source beat a lower-ranked one whatever the order' do
    ingest({ source_pfaf: 'b', average_height_value: 2500, average_height_unit: 'cm' })
    ingest({ source_flora_iberica: 'a', average_height_value: 1500, average_height_unit: 'cm' })

    expect(species.reload.average_height_cm).to eq(1500)
  end

  it 'lets the same source update its own value' do
    ingest({ source_flora_iberica: 'a', average_height_value: 1500, average_height_unit: 'cm' })
    ingest({ source_flora_iberica: 'a', average_height_value: 1600, average_height_unit: 'cm' })

    expect(species.reload.average_height_cm).to eq(1600)
    facts = species.species_facts.for_attribute('average_height_cm').order(:id)
    expect(facts.map(&:status)).to eq(%w[superseded active])
  end

  describe 'legacy values (filled column, no fact on record)' do
    it 'protects a legacy value from a weaker source' do
      species.update_columns(ph_minimum: 6.5)

      ingest({ source_pfaf: 'b', ph_minimum: 8.5 })

      expect(species.reload.ph_minimum).to eq(6.5)
      # The disagreement is still recorded rather than lost
      fact = species.species_facts.active_status.find_by(attribute_name: 'ph_minimum', source: 'pfaf')
      expect(fact.value).to eq('8.5')
    end

    it 'lets a source stronger than the legacy rank correct it' do
      species.update_columns(ph_minimum: 6.5)

      ingest({ ph_minimum: 5.0 }, source: 'community')

      expect(species.reload.ph_minimum).to eq(5.0)
    end

    it 'still lets any source fill a column that is empty' do
      expect(species.ph_minimum).to be_nil

      ingest({ source_pfaf: 'b', ph_minimum: 8.5 })

      expect(species.reload.ph_minimum).to eq(8.5)
    end

    it 'once a fact exists, the fact decides rather than the legacy rank' do
      # pfaf fills the gap and is now on record...
      ingest({ source_pfaf: 'b', ph_minimum: 8.5 })
      # ...so a source stronger than pfaf may correct it, even though it is
      # weaker than the legacy rank
      ingest({ source_catminat: 'c', ph_minimum: 6.5 })

      expect(species.reload.ph_minimum).to eq(6.5)
    end
  end

  describe 'closed vocabularies (allowed_values)' do
    it 'accepts a value from the vocabulary' do
      ingest({ source_usda: 'x', nitrogen_fixation: 'High' })

      expect(species.reload.nitrogen_fixation).to eq('High')
    end

    it 'rejects a value outside the vocabulary without assigning it' do
      ingest({ source_pfaf: 'x', nitrogen_fixation: 'very high' })

      expect(species.reload.nitrogen_fixation).to be_nil
      fact = species.species_facts.find_by(attribute_name: 'nitrogen_fixation')
      expect(fact.status).to eq('rejected')
      expect(fact.notes).to include('allowed vocabulary')
    end

    it 'is case-sensitive, so spelling drift is caught rather than absorbed' do
      ingest({ source_pfaf: 'x', nitrogen_fixation: 'high' })

      expect(species.reload.nitrogen_fixation).to be_nil
    end

    it 'leaves unconstrained text fields alone' do
      ingest({ source_pfaf: 'x', growth_habit: 'Forb/herb' })

      expect(species.reload.growth_habit).to eq('Forb/herb')
    end
  end

  describe 'bitmask columns' do
    it 'records the flag names rather than the raw bitmask' do
      ingest({ source_flora_iberica: 'a', bloom_months: 'mar|apr|may' })

      fact = species.species_facts.find_by(attribute_name: 'bloom_months')
      expect(fact.value).to eq('mar|apr|may')
      # 28 would be the raw value: meaningless on its own, and unstable if the
      # flag order ever changed
      expect(fact.value).not_to eq('28')
      expect(fact.value_numeric).to be_nil
    end

    it 'records readable names on a rejected claim too' do
      # edible_part is a flag; feed it through a source that loses arbitration
      ingest({ source_flora_iberica: 'a', edible_part: 'seeds' })
      ingest({ source_pfaf: 'b', edible_part: 'roots' })

      pfaf_fact = species.species_facts.find_by(attribute_name: 'edible_part', source: 'pfaf')
      expect(pfaf_fact.value).to eq('roots')
    end

    it 'leaves non-flag values untouched' do
      ingest({ source_flora_iberica: 'a', average_height_value: 250, average_height_unit: 'cm' })

      fact = species.species_facts.find_by(attribute_name: 'average_height_cm')
      expect(fact.value).to eq('250')
      expect(fact.value_numeric).to eq(250)
    end
  end

  describe 'fields beyond the completion set' do
    it 'protects taxon status from a weaker source' do
      ingest({ source_powo: 'p', status: 'accepted' })
      ingest({ source_gbif: 'g', status: 'doubtful' })

      expect(species.reload.status).to eq('accepted')
    end

    it 'records the losing nomenclature claim rather than dropping it' do
      ingest({ source_powo: 'p', status: 'accepted' })
      ingest({ source_gbif: 'g', status: 'doubtful' })

      values = species.species_facts.active_status.for_attribute('status').pluck(:source, :value)
      expect(values).to contain_exactly(%w[powo accepted], %w[gbif doubtful])
    end

    it 'lets a stronger source correct the status whatever the order' do
      ingest({ source_gbif: 'g', status: 'doubtful' })
      ingest({ source_powo: 'p', status: 'accepted' })

      expect(species.reload.status).to eq('accepted')
    end

    it 'protects raw source strings, which used to overwrite silently' do
      ingest({ source_powo: 'p', sexuality_raw: 'dioecious' })
      ingest({ source_catminat: 'c', sexuality_raw: 'dioique' })

      expect(species.reload.sexuality_raw).to eq('dioecious')
      expect(species.species_facts.for_attribute('sexuality_raw').count).to eq(2)
    end

    it 'arbitrates year and bibliography too' do
      ingest({ source_powo: 'p', year: 1753, bibliography: 'Sp. Pl.' })
      ingest({ source_gbif: 'g', year: 1900, bibliography: 'Elsewhere' })

      expect(species.reload.year).to eq(1753)
      expect(species.bibliography).to eq('Sp. Pl.')
    end

    it 'no longer wipes nomenclature when the name is simply absent' do
      # A targeted ingestion that omits scientific_name is not a disagreement,
      # but it used to clear author, bibliography and rank all the same.
      ingest({ source_powo: 'p', author: 'L.', bibliography: 'Sp. Pl.' })

      expect(species.reload.author).to eq('L.')
      expect(species.bibliography).to eq('Sp. Pl.')
    end

    it 'still drops nomenclature when the source names a different taxon' do
      species.update!(author: 'L.')

      ingest({ source_powo: 'p', scientific_name: 'Totally different', author: 'Someone else' })

      expect(species.reload.author).to eq('L.')
      expect(species.scientific_name).not_to eq('Totally different')
    end

    it 'leaves scientific_name out of arbitration' do
      # Renaming drives the slug, the plant linkage and the search tokens, so it
      # must not be settled silently between two crawlers.
      expect(Traits.arbitrated_fields).not_to include('scientific_name')
    end

    it 'keeps the completion set narrower than the arbitrated set' do
      expect(Traits.completion_fields).not_to include('status', 'rank', 'author')
      expect(Traits.arbitrated_fields).to include('status', 'rank', 'author')
    end
  end

end
