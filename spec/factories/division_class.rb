FactoryBot.define do
  factory :division_class do
    sequence(:name) {|n| "#{Faker::Space.moon}-#{n}" }
    division_id { Division.first&.id || create(:division).id }
  end
end
