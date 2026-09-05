FactoryBot.define do
  factory :species_image do
    species_id { Species.first&.id || create(:species).id }
    image_url { "https://example.com/#{SecureRandom.hex(4)}.jpg" }
    part { 'flower' }
  end
end
