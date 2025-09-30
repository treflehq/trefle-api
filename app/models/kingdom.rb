# == Schema Information
#
# Table name: kingdoms
#
#  id          :bigint           not null, primary key
#  inserted_at :datetime         not null
#  name        :string(255)
#  slug        :string(255)
#  created_at  :datetime
#  updated_at  :datetime         not null
#
# Indexes
#
#  kingdoms_name_index  (name) UNIQUE
#  kingdoms_slug_index  (slug) UNIQUE
#
class Kingdom < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged

  has_many :subkingdoms, dependent: :destroy
end
