FactoryBot.define do
  factory :record_correction do
    record { Plant.where.not(main_species_id: nil).order(completion_ratio: :desc).first.main_species }
    user { create(:user) }
    source_type { :observation }
  end
end
