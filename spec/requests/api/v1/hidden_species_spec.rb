require 'rails_helper'

# Species::HIDDEN_REASONS: a bryophyte (no reference arbitrates their names
# yet) or a fossil carrying data stays in the database and resolves by its
# slug, saying why in `hidden_reason`, but no list, search or count serves it.
RSpec.describe 'Hidden species', type: :request do
  let!(:user) { create(:user) }
  let(:genus) { Genus.first }

  let!(:listed) { create(:species, genus: genus, scientific_name: "#{genus.name} visibilis") }
  let!(:moss) { create(:species, genus: genus, scientific_name: "#{genus.name} muscosa", hidden_reason: 'bryophyte') }

  def get_json(path, params = {})
    get path, params: { token: user.token }.merge(params)
    response.parsed_body
  end

  def slugs(body)
    body['data'].pluck('slug')
  end

  it 'leaves the record out of the species list' do
    found = slugs(get_json('/api/v1/species', per_page: 100))

    expect(found).to include(listed.slug)
    expect(found).not_to include(moss.slug)
  end

  it 'leaves it out of the species of its genus' do
    found = slugs(get_json("/api/v1/genus/#{genus.slug}/species", per_page: 100))

    expect(found).to include(listed.slug)
    expect(found).not_to include(moss.slug)
  end

  it 'leaves its plant out of the plants list' do
    found = slugs(get_json('/api/v1/plants', per_page: 100))

    expect(found).to include(listed.slug)
    expect(found).not_to include(moss.slug)
  end

  it 'still serves it by its slug, saying why it is hidden' do
    body = get_json("/api/v1/species/#{moss.slug}")

    expect(response).to have_http_status(:ok)
    expect(body.dig('data', 'hidden_reason')).to eq('bryophyte')
  end

  it 'says null for a listed record' do
    body = get_json("/api/v1/species/#{listed.slug}")

    expect(body['data']).to include('hidden_reason' => nil)
  end

  it 'leaves it out of the counts' do
    expect(SiteCounts.species_count).to eq(Species.count - Species.where.not(hidden_reason: nil).count)
  end

  it 'refuses a reason outside the list' do
    moss.hidden_reason = 'unloved'

    expect(moss).not_to be_valid
  end

  describe 'search', search: true do
    it 'has no document for it' do
      Species.reindex
      Species.searchkick_index.refresh

      found = slugs(get_json('/api/v1/species/search', q: genus.name, per_page: 100))

      expect(found).to include(listed.slug)
      expect(found).not_to include(moss.slug)
    end
  end
end
