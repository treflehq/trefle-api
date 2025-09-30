FactoryBot.define do
  factory :division_order do
    sequence(:name) {|n| "#{Faker::Space.meteorite}-#{n}" }
    division_class_id { DivisionClass.first&.id || create(:division_class).id }
  end
end
