FactoryBot.define do
  factory :division do
    sequence(:name) {|n| "#{Faker::Space.star}-#{n}" }
    subkingdom_id { Subkingdom.first&.id || create(:subkingdom).id }
  end
end
