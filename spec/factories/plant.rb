FactoryBot.define do
  factory :plant do
    genus_id { Genus.first&.id || create(:genus).id }
    scientific_name { "#{Genus.find(genus_id).name} #{generate(:latin_epithet)}" }
  end
end
