FactoryBot.define do
  factory :kingdom do
    sequence(:name) {|n| "#{Faker::Space.constellation}-#{n}" }
  end
end
