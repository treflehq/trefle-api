FactoryBot.define do
  factory :plant do
    scientific_name { Faker::Space.genus }
    genus_id { Genus.first&.id || create(:genus).id }
  end
end
