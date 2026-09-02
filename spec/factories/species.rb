FactoryBot.define do
  factory :species do
    genus_id { Genus.first&.id || create(:genus).id }
    rank { 'species' }
    scientific_name { "#{Genus.find(genus_id).name} #{generate(:latin_epithet)}" }
  end
end
