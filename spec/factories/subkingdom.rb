FactoryBot.define do
  factory :subkingdom do
    sequence(:name) {|n| "#{Faker::Space.galaxy}-#{n}" }
    kingdom_id { Kingdom.first&.id || create(:kingdom).id }
  end
end
