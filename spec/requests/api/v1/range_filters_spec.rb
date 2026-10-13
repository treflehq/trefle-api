require 'rails_helper'

# `range[field]=min,max` on the collection endpoints. Before this spec the
# bounds were read with `to_i` into an exclusive Ruby range: `6.5` became 6,
# `8,10` dropped 10, an empty lower bound became 0 (so a negative temperature
# could not be searched) and `abc` was silently read as 0, returning the whole
# collection. Both bounds are now inclusive decimals, either side optional,
# and a non-numeric bound is a 400 -- on the ActiveRecord-backed lists and on
# the Searchkick-backed /search endpoints alike (see Rangeable.parse_bounds).
describe 'range[] filters', type: :request do
  let(:user) { create(:user) }

  # TestSeeds (spec/rails_helper.rb) loads a shared dataset once per suite, so
  # every list request below is narrowed to the fixtures by author.
  let(:author) { 'Zzzrangeauthor' }

  def names_for(path, range, extra = {})
    get path, params: { token: user.token, filter: { author: author }, range: range }.merge(extra)
    expect(response).to have_http_status(:success)
    JSON.parse(response.body)['data'].map {|s| s['scientific_name'] }
  end

  def error_for(path, range, extra = {})
    get path, params: { token: user.token, range: range }.merge(extra)
    JSON.parse(response.body)
  end

  %w[/api/v1/species /api/v1/plants].each do |path|
    describe "GET #{path} (ActiveRecord)" do
      let!(:acidic) do
        create(:species, scientific_name: 'Zzzrange acidae', author: author,
                         ph_minimum: 6.5, light: 8, minimum_temperature_deg_c: -10, maximum_height_cm: 50)
      end
      let!(:neutral) do
        create(:species, scientific_name: 'Zzzrange neutralae', author: author,
                         ph_minimum: 7.0, light: 10, minimum_temperature_deg_c: -2, maximum_height_cm: 150)
      end
      let!(:alkaline) do
        create(:species, scientific_name: 'Zzzrange alkalinae', author: author,
                         ph_minimum: 7.5, light: 11, minimum_temperature_deg_c: 5, maximum_height_cm: 300)
      end

      it 'reads decimal bounds instead of truncating them to integers' do
        # Truncated to 6...7 this used to keep 6.5 and drop 7.0.
        expect(names_for(path, ph_minimum: '6.4,7.2')).to contain_exactly(acidic.scientific_name, neutral.scientific_name)
        # The bound itself is kept (inclusive).
        expect(names_for(path, ph_minimum: '6.5,7.0')).to contain_exactly(acidic.scientific_name, neutral.scientific_name)
      end

      it 'includes the upper bound' do
        expect(names_for(path, light: '8,10')).to contain_exactly(acidic.scientific_name, neutral.scientific_name)
      end

      it 'rounds a decimal bound inwards on an integer column instead of truncating it' do
        # light >= 8.5 means light >= 9, not light >= 8.
        expect(names_for(path, light: '8.5,10')).to contain_exactly(neutral.scientific_name)
        # light <= 10.5 means light <= 10.
        expect(names_for(path, light: '8,10.5')).to contain_exactly(acidic.scientific_name, neutral.scientific_name)
      end

      it 'accepts an open lower bound with a negative upper bound' do
        # An empty lower bound used to become 0, so 0...-5 matched nothing.
        expect(names_for(path, minimum_temperature_deg_c: ',-5')).to contain_exactly(acidic.scientific_name)
      end

      it 'accepts a negative lower bound' do
        expect(names_for(path, minimum_temperature_deg_c: '-5,')).to contain_exactly(neutral.scientific_name, alkaline.scientific_name)
      end

      it 'accepts an open upper bound' do
        expect(names_for(path, maximum_height_cm: '150,')).to contain_exactly(neutral.scientific_name, alkaline.scientific_name)
      end

      it 'treats a range with no bound at all as no constraint' do
        expect(names_for(path, maximum_height_cm: ',')).to contain_exactly(acidic.scientific_name, neutral.scientific_name, alkaline.scientific_name)
      end

      it 'rejects a bound that is not a number with a 400 naming the field and the value' do
        body = error_for(path, light: 'abc,10')

        expect(response).to have_http_status(:bad_request)
        expect(body['error']).to eq(true)
        expect(body['code']).to eq('bad_request')
        expect(body['message']).to include('light').and include('"abc"').and include('range[light]=min,max')
      end

      it 'rejects a third comma-separated value as a non-numeric upper bound' do
        body = error_for(path, light: '1,2,3')

        expect(response).to have_http_status(:bad_request)
        expect(body['message']).to include('"2,3"')
      end
    end
  end

  # search: true re-enables Searchkick callbacks for the example (disabled
  # suite-wide in spec_helper.rb); the model indexes through a Sidekiq queue
  # nothing drains during specs, so index inline and refresh before searching
  # (same recipe as search_filter_field_aliases_spec.rb).
  def index_synchronously(&block)
    Searchkick.callbacks(:inline, &block)
    Species.searchkick_index.refresh
  end

  %w[/api/v1/species/search /api/v1/plants/search].each do |path|
    describe "GET #{path} (Searchkick)", search: true do
      before do
        index_synchronously do
          @acidic = create(:species, scientific_name: 'Zzzrange acidae', author: author,
                                     ph_minimum: 6.5, light: 8, minimum_temperature_deg_c: -10, maximum_height_cm: 50)
          @neutral = create(:species, scientific_name: 'Zzzrange neutralae', author: author,
                                      ph_minimum: 7.0, light: 10, minimum_temperature_deg_c: -2, maximum_height_cm: 150)
          @alkaline = create(:species, scientific_name: 'Zzzrange alkalinae', author: author,
                                       ph_minimum: 7.5, light: 11, minimum_temperature_deg_c: 5, maximum_height_cm: 300)
        end
      end

      # The transaction rollback removes the rows but not their documents: left
      # in the shared index, the stale hits of earlier examples push the live
      # ones past the first page of results.
      after do
        [@acidic, @neutral, @alkaline].each {|species| Species.searchkick_index.remove(species) }
        Species.searchkick_index.refresh
      end

      def search_names(path, range)
        get path, params: { token: user.token, q: 'Zzzrange', range: range }
        expect(response).to have_http_status(:success)
        JSON.parse(response.body)['data'].map {|s| s['scientific_name'] }
      end

      it 'reads decimal bounds' do
        expect(search_names(path, ph_minimum: '6.4,7.2')).to contain_exactly(@acidic.scientific_name, @neutral.scientific_name)
      end

      it 'includes the upper bound' do
        expect(search_names(path, light: '8,10')).to contain_exactly(@acidic.scientific_name, @neutral.scientific_name)
      end

      it 'rounds a decimal bound inwards on an integer column' do
        expect(search_names(path, light: '8.5,10')).to contain_exactly(@neutral.scientific_name)
      end

      it 'accepts an open lower bound with a negative upper bound' do
        expect(search_names(path, minimum_temperature_deg_c: ',-5')).to contain_exactly(@acidic.scientific_name)
      end

      it 'accepts an open upper bound' do
        expect(search_names(path, maximum_height_cm: '150,')).to contain_exactly(@neutral.scientific_name, @alkaline.scientific_name)
      end

      it 'rejects a bound that is not a number with a 400 naming the field and the value' do
        body = error_for(path, { light: 'abc,10' }, q: 'Zzzrange')

        expect(response).to have_http_status(:bad_request)
        expect(body['error']).to eq(true)
        expect(body['message']).to include('light').and include('"abc"')
      end
    end
  end

  describe 'GET /api/v1/species filter[nitrogen_fixation]' do
    let!(:fixer) { create(:species, scientific_name: 'Zzznitro fixans', author: 'Zzznitroauthor', nitrogen_fixation: 'High') }
    let!(:non_fixer) { create(:species, scientific_name: 'Zzznitro inertae', author: 'Zzznitroauthor', nitrogen_fixation: 'None') }

    it 'filters on the value, case-insensitively, like the other string columns' do
      get '/api/v1/species', params: { token: user.token, filter: { author: 'Zzznitroauthor', nitrogen_fixation: 'high' } }
      body = JSON.parse(response.body)

      expect(response).to have_http_status(:success)
      expect(body['data'].map {|s| s['scientific_name'] }).to contain_exactly(fixer.scientific_name)
    end

    it 'filter_not[nitrogen_fixation]=null keeps only species with a value' do
      unknown = create(:species, scientific_name: 'Zzznitro ignotae', author: 'Zzznitroauthor', nitrogen_fixation: nil)
      get '/api/v1/species', params: { token: user.token, filter: { author: 'Zzznitroauthor' }, filter_not: { nitrogen_fixation: 'null' } }
      body = JSON.parse(response.body)

      expect(response).to have_http_status(:success)
      names = body['data'].map {|s| s['scientific_name'] }
      expect(names).to contain_exactly(fixer.scientific_name, non_fixer.scientific_name)
      expect(names).not_to include(unknown.scientific_name)
    end
  end
end
