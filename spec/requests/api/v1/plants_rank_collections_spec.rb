require 'rails_helper'

# Regression guard for #364: PlantSerializer renders six sibling collections
# (species/subspecies/varieties/hybrids/forms/subvarieties), one per
# Species#rank value. Each used to be its own `species.<rank>_rank` scope,
# so rendering a single plant paid one `species` query per rank present.
# Pin the query count against the `species` table specifically, since the
# request as a whole issues other queries too (genus, foreign sources...).
RSpec.describe 'Plant rank collections', type: :request do

  let!(:user) { create(:user) }
  let(:genus) { Genus.first }

  # Filters SQL notifications down to statements that hit the species table,
  # so growing/shrinking unrelated queries elsewhere doesn't move this count.
  def count_species_queries(&block)
    count = 0

    counter = lambda do |*, payload|
      next if %w[SCHEMA CACHE].include?(payload[:name])

      count += 1 if payload[:sql].match?(/FROM "species"/)
    end

    ActiveSupport::Notifications.subscribed(counter, 'sql.active_record', &block)

    count
  end

  it 'issues a single species query for the six rank collections on /api/v1/plants/:id' do
    root = create(:species, genus: genus, scientific_name: "#{genus.name} radix")
    plant = root.plant

    create(:species, genus: genus, rank: 'ssp', main_species: root, scientific_name: "#{root.scientific_name} ssp. minor")
    create(:species, genus: genus, rank: 'var', main_species: root, scientific_name: "#{root.scientific_name} var. minor")
    create(:species, genus: genus, rank: 'form', main_species: root, scientific_name: "#{root.scientific_name} form. minor")
    create(:species, genus: genus, rank: 'hybrid', main_species: root, scientific_name: "#{genus.name} × minor")
    create(:species, genus: genus, rank: 'subvar', main_species: root, scientific_name: "#{root.scientific_name} subvar. minor")

    count = count_species_queries { get "/api/v1/plants/#{plant.slug}", params: { token: user.token } }

    expect(response).to have_http_status(:ok)
    # 1 to resolve the slug (Species.friendly_or_synonym!) + 1 to load
    # plant.species once for all six rank collections — not the pre-fix
    # 1 + 6 (one scope query per rank, run whether or not it has rows).
    expect(count).to eq(2)
  end

  it 'still returns every species under its matching rank key' do
    root = create(:species, genus: genus, scientific_name: "#{genus.name} radix")
    plant = root.plant

    variety = create(:species, genus: genus, rank: 'var', main_species: root, scientific_name: "#{root.scientific_name} var. minor")
    hybrid = create(:species, genus: genus, rank: 'hybrid', main_species: root, scientific_name: "#{genus.name} × minor")

    get "/api/v1/plants/#{plant.slug}", params: { token: user.token }
    body = response.parsed_body['data']

    expect(body['species'].pluck('id')).to contain_exactly(root.id)
    expect(body['varieties'].pluck('id')).to contain_exactly(variety.id)
    expect(body['hybrids'].pluck('id')).to contain_exactly(hybrid.id)
    expect(body['subspecies']).to be_empty
    expect(body['forms']).to be_empty
    expect(body['subvarieties']).to be_empty
  end

end
