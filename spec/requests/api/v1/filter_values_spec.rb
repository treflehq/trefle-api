require 'rails_helper'

# Values outside a closed vocabulary used to answer 200: ActiveRecord casts an
# unknown enum name to NULL (`filter[status]=foobar` returned the species
# without a status), active_flag casts an unknown flag to 0 (no rows), and an
# inverted range matched nothing. They now answer 400 with the key, the value
# and what is accepted (Filterable#convert_value, Rangeable.parse_bounds).
describe 'Filter values validation', type: :request do
  let(:user) { create(:user) }

  # TestSeeds (spec/rails_helper.rb) loads a shared dataset once per suite:
  # list requests are narrowed to the fixtures by author.
  let(:author) { 'Zzzvalueauthor' }

  def get_json(path, params)
    get path, params: params.merge(token: user.token)
    JSON.parse(response.body)
  end

  def names_for(path, filter)
    body = get_json(path, filter: { author: author }.merge(filter))
    expect(response).to have_http_status(:success)
    body['data'].map {|s| s['scientific_name'] }
  end

  %w[/api/v1/species /api/v1/plants].each do |path|
    describe "GET #{path}" do
      let!(:accepted) do
        create(:species, scientific_name: 'Zzzvalue acceptae', author: author, status: :accepted, duration: [:perennial])
      end
      let!(:unknown) do
        create(:species, scientific_name: 'Zzzvalue ignotae', author: author, status: :unknown, duration: [:annual])
      end

      {
        status: ['foobar', 'accepted, unknown, rejected, doubtful'],
        rank: ['cultivar', 'species, ssp, var, form, hybrid, subvar'],
        establishment: ['natif', 'native, introduced, doubtful, absent, extinct'],
        duration: ['evergreen', 'annual, biennial, perennial'],
        flower_color: ['pink', 'white, red, brown'],
        bloom_months: ['january', 'jan, feb, mar'],
        sexuality: ['bisexual', 'hermaphrodite, monoecious'],
        nitrogen_fixation: ['very high', 'None, Low, Medium, High']
      }.each do |key, (bad, allowed)|
        it "rejects filter[#{key}]=#{bad} with a 400 naming the key, the value and the accepted values" do
          body = get_json(path, filter: { key => bad })

          expect(response).to have_http_status(:bad_request)
          expect(body['code']).to eq('bad_request')
          expect(body['message']).to include(key.to_s).and include(bad.inspect).and include(allowed)
        end
      end

      it 'rejects an unknown value among several comma-separated ones' do
        body = get_json(path, filter: { status: 'accepted,foobar' })

        expect(response).to have_http_status(:bad_request)
        expect(body['message']).to include('"foobar"')
      end

      it 'rejects an unknown value in filter_not too' do
        body = get_json(path, filter_not: { status: 'foobar' })

        expect(response).to have_http_status(:bad_request)
        expect(body['message']).to include('status').and include('"foobar"')
      end

      it 'still filters on a known value' do
        expect(names_for(path, status: 'accepted')).to eq([accepted.scientific_name])
      end

      it 'matches an enum name case-insensitively (it used to be cast to NULL)' do
        expect(names_for(path, status: 'Accepted')).to eq([accepted.scientific_name])
      end

      it 'still accepts the stored integer of an enum' do
        expect(names_for(path, status: '1')).to eq([unknown.scientific_name])
      end

      it 'matches a flag name case-insensitively' do
        expect(names_for(path, duration: 'Perennial')).to eq([accepted.scientific_name])
      end

      it 'keeps accepting several known values' do
        expect(names_for(path, status: 'accepted,unknown')).to contain_exactly(accepted.scientific_name, unknown.scientific_name)
      end

      it 'keeps accepting null in filter_not' do
        get_json(path, filter_not: { status: 'null' })

        expect(response).to have_http_status(:success)
      end

      it 'points a numeric field given to filter[] to range[]' do
        body = get_json(path, filter: { light: '9' })

        expect(response).to have_http_status(:bad_request)
        expect(body['message']).to include('light is a numeric field').and include('range[light]=9,9')
      end

      it 'rejects an inverted range with a 400 naming the bounds' do
        body = get_json(path, range: { ph_minimum: '7,5' })

        expect(response).to have_http_status(:bad_request)
        expect(body['message']).to include('ph_minimum').and include('lower bound 7 is greater than the upper bound 5')
      end

      it 'does not take a decimal range with no integer in it for an inverted one' do
        get_json(path, filter: { author: author }, range: { light: '6.2,6.8' })

        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'GET /api/v1/species/search', search: true do
    it 'rejects an unknown enum value with a 400' do
      body = get_json('/api/v1/species/search', q: 'Zzzvalue', filter: { status: 'foobar' })

      expect(response).to have_http_status(:bad_request)
      expect(body['message']).to include('status').and include('"foobar"').and include('accepted')
    end

    it 'rejects an unknown filter_not value with a 400' do
      get_json('/api/v1/plants/search', q: 'Zzzvalue', filter_not: { rank: 'cultivar' })

      expect(response).to have_http_status(:bad_request)
    end

    it 'rejects an inverted range with a 400' do
      body = get_json('/api/v1/species/search', q: 'Zzzvalue', range: { ph_minimum: '7,5' })

      expect(response).to have_http_status(:bad_request)
      expect(body['message']).to include('greater than the upper bound')
    end

    it 'searches with a known value spelled in another case' do
      get_json('/api/v1/species/search', q: 'Zzzvalue', filter: { status: 'Accepted' })

      expect(response).to have_http_status(:success)
    end
  end
end
