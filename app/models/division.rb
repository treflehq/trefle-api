# == Schema Information
#
# Table name: divisions
#
#  id            :integer          not null, primary key
#  name          :string(255)
#  slug          :string(255)
#  subkingdom_id :integer
#  inserted_at   :datetime         not null
#  updated_at    :datetime         not null
#  created_at    :datetime
#
# Indexes
#
#  divisions_name_index  (name) UNIQUE
#  divisions_slug_index  (slug) UNIQUE
#

class Division < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged

  belongs_to :subkingdom
  has_many :division_classes, dependent: :destroy
end
