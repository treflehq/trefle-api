require 'rails_helper'

# #280: the Searchkick-backed /search endpoints must agree with the
# AR-backed list endpoints on what a public filter key means. `image_url` is
# the public name for the `main_image_url` column (see
# Scopes::Species::FIELD_ALIASES); before this fix the search endpoints
# passed `image_url` straight into Searchkick, which has no such indexed
# field, so the filter silently matched nothing instead of raising or
# filtering correctly.
describe 'Search filter field aliases (#280)', type: :request do
  let(:user) { create(:user) }

  # search: true switches Searchkick.disable_callbacks (set suite-wide in
  # spec_helper.rb) back on for this example, but the model is configured
  # with `callbacks: :queue` (app/models/concerns/search/species.rb), which
  # only enqueues a Sidekiq job -- nothing processes that queue inline
  # during specs. Force synchronous indexing explicitly, then refresh so the
  # write is visible to the search we issue right after.
  def index_synchronously(&block)
    Searchkick.callbacks(:inline, &block)
    Species.searchkick_index.refresh
  end

  describe 'GET /api/v1/species/search' do
    it 'filter_not[image_url]=null matches the AR-backed index endpoint, not zero results', search: true do
      with_photo = nil
      without_photo = nil
      index_synchronously do
        with_photo = create(:species, scientific_name: 'Zzztestus withphotoae', main_image_url: 'https://example.com/a.jpg')
        without_photo = create(:species, scientific_name: 'Zzztestus nophotoae', main_image_url: nil)
      end

      get '/api/v1/species/search', params: { q: 'Zzztestus', token: user.token, filter_not: { image_url: 'null' } }
      body = JSON.parse(response.body)

      expect(response).to have_http_status(:success)
      names = body['data'].map {|s| s['scientific_name'] }
      expect(names).to include(with_photo.scientific_name)
      expect(names).not_to include(without_photo.scientific_name)
    end
  end

  describe 'GET /api/v1/plants/search' do
    it 'filter_not[image_url]=null matches the AR-backed index endpoint, not zero results', search: true do
      with_photo = nil
      without_photo = nil
      index_synchronously do
        with_photo = create(:species, scientific_name: 'Zzzplantus withphotoae', main_image_url: 'https://example.com/a.jpg')
        without_photo = create(:species, scientific_name: 'Zzzplantus nophotoae', main_image_url: nil)
      end

      get '/api/v1/plants/search', params: { q: 'Zzzplantus', token: user.token, filter_not: { image_url: 'null' } }
      body = JSON.parse(response.body)

      expect(response).to have_http_status(:success)
      names = body['data'].map {|s| s['scientific_name'] }
      expect(names).to include(with_photo.scientific_name)
      expect(names).not_to include(without_photo.scientific_name)
    end
  end

  # Audit finding from #280: `establishment` has the same shape of bug as
  # `image_url` had (a FILTERABLE_FIELDS key with no equivalent in the
  # Searchkick index -- it lives on the species_distributions association,
  # never indexed), but isn't fixed here: unlike image_url there is no
  # single real column to alias to, it would need indexing
  # species_distributions data into Searchkick. This test pins the current
  # (silently-wrong) behavior so it doesn't regress unnoticed and is easy to
  # find for whoever picks that up.
  describe 'GET /api/v1/species/search filter[establishment] (known gap, not fixed by #280)' do
    it 'silently returns no results instead of filtering, unlike GET /api/v1/species' do
      species = nil
      index_synchronously do
        species = create(:species, scientific_name: 'Zzzestablishmentus testae')
        SpeciesDistribution.create!(species: species, zone: Zone.first, establishment: 'native')
        species.save!
      end

      get '/api/v1/species/search', params: { q: 'Zzzestablishmentus', token: user.token, filter: { establishment: 'native' } }
      body = JSON.parse(response.body)

      expect(response).to have_http_status(:success)
      expect(body['data']).to eq([])
    end
  end
end
