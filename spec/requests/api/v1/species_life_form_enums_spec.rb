require 'rails_helper'

# #385: four integer columns carried no enum, so the readable labels TRY
# facts claim could not be promoted. They round-trip now: fact -> column ->
# payload, filterable by label.
describe 'Species life-form and morphology enums', type: :request do
  let(:user) { create(:user) }
  let(:species) { create(:species) }

  def record(attr, value)
    SpeciesFact.record!(species: species, attribute_name: attr, source: 'try', value: value, n_observations: 5)
  end

  it 'leaves sexuality undocumented (nil) on a new species, not 0' do
    expect(Species.new.sexuality).to be_nil
    expect(Species.columns_hash['sexuality'].null).to be(true)
  end

  it 'numbers every value from 1, so a legacy 0 never decodes to a label' do
    %i[biological_types fruit_shapes sexualities inflorescence_types].each do |enum|
      expect(Species.public_send(enum).values.min).to eq(1)
    end
  end

  it 'promotes the labels TRY facts carry' do
    record('biological_type', 'hemicryptophyte')
    record('fruit_shape', 'achene')
    record('sexuality', 'andromonoecious')
    record('inflorescence_type', 'panicle')

    result = Migrators::FactPromotion.run(source: 'try', dry_run: false)

    expect(result.rejected[:unconvertible]).to eq(0)
    species.reload
    expect(species.biological_type).to eq('hemicryptophyte')
    expect(species.fruit_shape).to eq('achene')
    expect(species.sexuality).to eq('andromonoecious')
    expect(species.inflorescence_type).to eq('panicle')
  end

  it 'renders the labels in the payload' do
    species.update!(biological_type: :therophyte, fruit_shape: :capsule, sexuality: :dioecious,
                    inflorescence_type: :umbel)

    get "/api/v1/species/#{species.id}", params: { token: user.token }
    data = JSON.parse(response.body)['data']

    expect(response).to have_http_status(:ok)
    expect(data['specifications']['biological_type']).to eq('therophyte')
    expect(data['fruit_or_seed']['shape']).to eq('capsule')
    expect(data['flower']['sexuality']).to eq('dioecious')
    expect(data['flower']['inflorescence_type']).to eq('umbel')
  end

  it 'declares the vocabularies in the species schema' do
    props = Schemas::V1::SCHEMAS[:species].deep_stringify_keys['properties']
    {
      %w[specifications biological_type] => 'therophyte',
      %w[fruit_or_seed shape] => 'capsule',
      %w[flower sexuality] => 'dioecious',
      %w[flower inflorescence_type] => 'umbel'
    }.each do |(section, field), label|
      property = props.dig(section, 'properties', field)
      expect(JSON::Validator.validate(property, label)).to be(true), "#{section}.#{field} rejects #{label}"
      expect(JSON::Validator.validate(property, 'not-a-label')).to be(false), "#{section}.#{field} accepts anything"
    end
  end

  it 'filters by label' do
    species.update!(sexuality: :dioecious)
    other = create(:species)
    other.update!(sexuality: :monoecious)

    get '/api/v1/species', params: { token: user.token, filter: { sexuality: 'dioecious' } }
    ids = JSON.parse(response.body)['data'].pluck('id')

    expect(response).to have_http_status(:ok)
    expect(ids).to include(species.id)
    expect(ids).not_to include(other.id)
  end

  it 'lets the ingester take a label' do
    expect(Ingester::Converter::Enum.resolve!({ biological_type: 'geophyte' })).to eq(biological_type: :geophyte)
  end
end
