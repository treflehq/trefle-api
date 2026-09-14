require 'rails_helper'

# Regression guard for #363: explore/species/_species_menu.html.erb walks
# species.foreign_sources_plants.each { |fsp| fsp.foreign_source } for every
# species rendering the sidebar menu, and separately calls
# species.foreign_sources.any? to decide whether to show the section at all.
# Neither association was preloaded on any of the three entry points that
# render the partial, so the menu cost one query per linked source (doubled
# by the .any? check) — 7,654 grouped Sentry events (API-52, API-53, API-5D).
# Pin the query count flat as synonyms and sources are added instead of
# guessing at a fixed number.
RSpec.describe 'Explore foreign sources menu preloading', type: :request do

  let(:species) { create(:species) }
  let(:sources) { ForeignSource.limit(4).to_a }
  let(:synonym_suffixes) { %w[alpha beta gamma] }

  def link_source!(record, source)
    ForeignSourcesPlant.create!(record: record, foreign_source: source, fid: "fid-#{record.id}-#{source.id}")
  end

  # The species page's synonyms section walks each synonym's own
  # foreign_sources_plants (see preload_foreign_sources_for) -- give every
  # synonym a source of its own so growing the synonym list would surface a
  # per-synonym N+1 too, not just the top-level one.
  def add_synonym!(record, suffix)
    synonym = Synonym.create!(record: record, name: "#{record.scientific_name} #{suffix}")
    link_source!(synonym, sources[0])
    synonym
  end

  it 'keeps the query count flat on /explore/species/:slug as more synonyms and foreign sources are added' do
    link_source!(species, sources[0])
    add_synonym!(species, synonym_suffixes[0])

    baseline = count_queries { get explore_species_path(species) }
    expect(response).to have_http_status(:ok)

    sources[1..].each {|source| link_source!(species, source) }
    synonym_suffixes[1..].each {|suffix| add_synonym!(species, suffix) }

    with_more_rows = count_queries { get explore_species_path(species) }
    expect(response).to have_http_status(:ok)

    expect(with_more_rows).to eq(baseline)
  end

  it 'keeps the query count flat on /explore/species/:slug/corrections as more synonyms and foreign sources are added' do
    link_source!(species, sources[0])
    add_synonym!(species, synonym_suffixes[0])

    baseline = count_queries { get explore_species_record_corrections_path(species) }
    expect(response).to have_http_status(:ok)

    sources[1..].each {|source| link_source!(species, source) }
    synonym_suffixes[1..].each {|suffix| add_synonym!(species, suffix) }

    with_more_rows = count_queries { get explore_species_record_corrections_path(species) }
    expect(response).to have_http_status(:ok)

    expect(with_more_rows).to eq(baseline)
  end

  it 'keeps the query count flat on /explore/corrections/:id as more synonyms and foreign sources are added' do
    correction = create(:record_correction, record: species)
    link_source!(species, sources[0])
    add_synonym!(species, synonym_suffixes[0])

    baseline = count_queries { get explore_record_correction_path(correction) }
    expect(response).to have_http_status(:ok)

    sources[1..].each {|source| link_source!(species, source) }
    synonym_suffixes[1..].each {|suffix| add_synonym!(species, suffix) }

    with_more_rows = count_queries { get explore_record_correction_path(correction) }
    expect(response).to have_http_status(:ok)

    expect(with_more_rows).to eq(baseline)
  end

  it 'renders the links section from the preloaded association, unchanged, once sources are linked' do
    link_source!(species, sources[0])
    link_source!(species, sources[1])

    get explore_species_path(species)

    expect(response.body).to include("See on #{sources[0].name}")
    expect(response.body).to include("See on #{sources[1].name}")
  end

  it 'hides the links section entirely when the species has no foreign source' do
    get explore_species_path(species)

    expect(response.body).not_to include('Links')
  end
end
