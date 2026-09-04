# == Schema Information
#
# Table name: division_classes
#
#  id          :integer          not null, primary key
#  name        :string(255)
#  slug        :string(255)
#  division_id :integer
#  inserted_at :datetime         not null
#  updated_at  :datetime         not null
#  created_at  :datetime
#
# Indexes
#
#  division_classes_division_id_index  (division_id)
#  division_classes_name_index         (name) UNIQUE
#

class DivisionClass < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged

  belongs_to :division, optional: true # @TODO to remove
  has_many :division_orders, dependent: :destroy
end
