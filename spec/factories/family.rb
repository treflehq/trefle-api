FactoryBot.define do
  factory :family do
    name { Faker::Space.family }
    division_order_id { DivisionOrder.first&.id || create(:division_order).id }
  end
end
