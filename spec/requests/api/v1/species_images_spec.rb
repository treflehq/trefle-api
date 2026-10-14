require 'rails_helper'

describe 'GET /api/v1/species/:id — images with no identified part', type: :request do
  let(:user) { create(:user) }
  let(:species) { create(:species) }

  before do
    create(:species_image, species_id: species.id, part: 'flower')
    create(:species_image, species_id: species.id, part: nil)
  end

  it 'groups images with no part under an explicit "unknown" key, never an empty string' do
    get "/api/v1/species/#{species.id}", params: { token: user.token }
    body = JSON.parse(response.body)

    images = body.dig('data', 'images')

    expect(response).to have_http_status(:success)
    expect(images).to have_key('unknown')
    expect(images['unknown'].size).to eq(1)
    expect(images).not_to have_key('')
  end
end

describe 'Image licences in API payloads', type: :request do
  let(:user) { create(:user) }
  let(:species) { create(:species) }
  let(:url) { 'https://bs.plantnet.org/image/o/abc123' }
  let(:expected) do
    {
      'image_url' => url, 'thumbnail_url' => 'https://bs.plantnet.org/image/s/abc123',
      'copyright' => 'Taken Mar 14, 2022 by Jane Doe (cc-by-nc)',
      'licence' => 'CC-BY-NC', 'licence_url' => 'https://creativecommons.org/licenses/by-nc/',
      'author' => 'Jane Doe', 'commercial_use_allowed' => false
    }
  end

  before do
    create(:species_image, species_id: species.id, part: 'flower', image_url: url,
                           copyright: 'Taken Mar 14, 2022 by Jane Doe (cc-by-nc)')
    species.update_columns(main_image_url: url)
  end

  it 'gives every image and the main image their licence, author and thumbnail' do
    get "/api/v1/species/#{species.id}", params: { token: user.token }
    data = JSON.parse(response.body)['data']

    expect(data.dig('images', 'flower', 0)).to include(expected)
    expect(data['image_url']).to eq(url)
    expect(data['main_image']).to include(expected)
  end

  it 'gives the main image terms in species lists, and null without a main image' do
    bare = create(:species)

    get '/api/v1/species', params: { token: user.token }
    rows = JSON.parse(response.body)['data'].index_by {|r| r['id'] }

    expect(rows[species.id]['main_image']).to include(expected)
    expect(rows[bare.id]['main_image']).to be_nil
  end
end
