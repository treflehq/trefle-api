# == Schema Information
#
# Table name: subkingdoms
#
#  id          :integer          not null, primary key
#  name        :string(255)
#  slug        :string(255)
#  kingdom_id  :integer
#  inserted_at :datetime         not null
#  updated_at  :datetime         not null
#  created_at  :datetime
#
# Indexes
#
#  subkingdoms_name_index  (name) UNIQUE
#  subkingdoms_slug_index  (slug) UNIQUE
#

class Subkingdom < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged

  belongs_to :kingdom
  has_many :divisions, dependent: :destroy
end
