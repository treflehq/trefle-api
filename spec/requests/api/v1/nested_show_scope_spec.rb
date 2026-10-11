require 'rails_helper'

# A nested show answers only for a record of the parent in the path, like the
# nested index; /genus/hieracium/species/eruca-vesicaria used to return Eruca.
RSpec.describe 'Nested show scoping', type: :request do
  let(:user) { create(:user) }
  let(:species) { Species.friendly.find('abies-alba') }
  let(:other_genus) { Genus.where.not(id: species.genus_id).first }

  %w[species plants].each do |kind|
    it "serves /genus/:genus_id/#{kind}/:id for a species of that genus" do
      get "/api/v1/genus/#{species.genus.slug}/#{kind}/#{species.slug}", params: { token: user.token }
      expect(response).to have_http_status(:ok)
    end

    it "answers 404 on /genus/:genus_id/#{kind}/:id for a species of another genus" do
      get "/api/v1/genus/#{other_genus.slug}/#{kind}/#{species.slug}", params: { token: user.token }
      expect(response).to have_http_status(:not_found)
    end
  end

  it 'answers 404 on /plants/:plant_id/species/:id for a species of another plant' do
    other = Species.where.not(plant_id: [species.plant_id, nil]).first

    get "/api/v1/plants/#{other.plant.slug}/species/#{species.slug}", params: { token: user.token }

    expect(response).to have_http_status(:not_found)
  end

  it 'answers 404 on /families/:family_id/genus/:id for a genus of another family' do
    other_family = Family.where.not(id: species.genus.family_id).first

    get "/api/v1/families/#{other_family.slug}/genus/#{species.genus.slug}", params: { token: user.token }

    expect(response).to have_http_status(:not_found)
  end

  it 'still serves /families/:family_id/genus/:id for a genus of that family' do
    get "/api/v1/families/#{species.genus.family.slug}/genus/#{species.genus.slug}", params: { token: user.token }
    expect(response).to have_http_status(:ok)
  end
end
