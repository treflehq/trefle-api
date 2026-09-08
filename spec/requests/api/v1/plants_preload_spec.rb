require 'rails_helper'

# Regression guard for #281: SpeciesLightSerializer reads `synonyms` and
# `plant.slug` for every row it serializes. Without preloading both
# associations (on top of `genus`), the plants collection pays two extra
# queries per row — pin the query count so it can't grow with the page
# again instead of guessing at a fixed number.
RSpec.describe 'Plants collection preloading', type: :request do

  # Distinct lowercase epithets: ScientificNameStructureValidator requires
  # letters/hyphens only (no digits) for each part of the binomial.
  let(:epithets) { %w[unus duo tria quattuor quinque sex septem] }

  # Eager (`let!`) so the user row is created before the first
  # count_queries block runs — otherwise `user.token` lazily inserts the
  # user on the first call only, throwing the baseline count off by four.
  let!(:user) { create(:user) }
  let(:genus) { Genus.first }

  def create_root_plant!(epithet)
    species = create(:species, genus: genus, scientific_name: "#{genus.name} #{epithet}")
    Synonym.create!(record: species, name: "#{species.scientific_name}-old")
    species
  end

  def create_variety!(root_species, epithet)
    species = create(
      :species,
      genus: genus,
      rank: 'var',
      main_species: root_species,
      scientific_name: "#{root_species.scientific_name} var. #{epithet}"
    )
    Synonym.create!(record: species, name: "#{species.scientific_name}-old")
    species
  end

  it 'keeps the query count flat as more plants (each with a synonym) are added on /api/v1/plants' do
    create_root_plant!(epithets[0])

    baseline = count_queries { get '/api/v1/plants', params: { token: user.token } }
    expect(response).to have_http_status(:ok)

    epithets[1..].each {|epithet| create_root_plant!(epithet) }

    with_more_rows = count_queries { get '/api/v1/plants', params: { token: user.token } }
    expect(response).to have_http_status(:ok)

    expect(with_more_rows).to eq(baseline)
  end

  it 'keeps the query count flat on /api/v1/genus/:genus_id/plants (that branch preloaded nothing at all)' do
    create_root_plant!(epithets[0])

    baseline = count_queries { get "/api/v1/genus/#{genus.slug}/plants", params: { token: user.token } }
    expect(response).to have_http_status(:ok)

    epithets[1..].each {|epithet| create_root_plant!(epithet) }

    with_more_rows = count_queries { get "/api/v1/genus/#{genus.slug}/plants", params: { token: user.token } }
    expect(response).to have_http_status(:ok)

    expect(with_more_rows).to eq(baseline)
  end

  it 'keeps the query count flat on /api/v1/distributions/:zone_id/plants (that branch also preloaded nothing at all)' do
    zone = Zone.first
    create_root_plant!(epithets[0]).species_distributions.create!(zone: zone)

    baseline = count_queries { get "/api/v1/distributions/#{zone.slug}/plants", params: { token: user.token } }
    expect(response).to have_http_status(:ok)

    epithets[1..].each {|epithet| create_root_plant!(epithet).species_distributions.create!(zone: zone) }

    with_more_rows = count_queries { get "/api/v1/distributions/#{zone.slug}/plants", params: { token: user.token } }
    expect(response).to have_http_status(:ok)

    expect(with_more_rows).to eq(baseline)
  end

  it 'keeps the query count flat on the nested species collections of /api/v1/plants/:id (PlantSerializer)' do
    root = create_root_plant!('radix')
    plant = root.plant
    create_variety!(root, epithets[0])

    baseline = count_queries { get "/api/v1/plants/#{plant.slug}", params: { token: user.token } }
    expect(response).to have_http_status(:ok)

    epithets[1..].each {|epithet| create_variety!(root, epithet) }

    with_more_rows = count_queries { get "/api/v1/plants/#{plant.slug}", params: { token: user.token } }
    expect(response).to have_http_status(:ok)

    expect(with_more_rows).to eq(baseline)
  end

end
