# == Schema Information
#
# Table name: genuses
#
#  id          :bigint           not null, primary key
#  inserted_at :datetime         not null
#  name        :string(255)
#  slug        :string(255)
#  created_at  :datetime
#  updated_at  :datetime         not null
#  family_id   :bigint
#
# Indexes
#
#  genuses_family_id_index  (family_id)
#  genuses_name_index       (name) UNIQUE
#  genuses_slug_index       (slug) UNIQUE
#
# Foreign Keys
#
#  genuses_family_id_fkey  (family_id => families.id)
#
FactoryBot.define do
  factory :genus do
    name { Faker::Space.genus }
    family_id { Family.first&.id || create(:family).id }
  end
end
