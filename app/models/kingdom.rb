# == Schema Information
#
# Table name: kingdoms
#
#  id          :integer          not null, primary key
#  name        :string(255)
#  slug        :string(255)
#  inserted_at :datetime         not null
#  updated_at  :datetime         not null
#  created_at  :datetime
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
