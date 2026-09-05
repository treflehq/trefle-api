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
