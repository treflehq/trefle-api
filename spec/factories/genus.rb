FactoryBot.define do
  factory :genus do
    name { generate(:latin_genus) }
    family_id { Family.first&.id || create(:family).id }
  end
end
