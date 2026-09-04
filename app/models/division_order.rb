# == Schema Information
#
# Table name: division_orders
#
#  id                :integer          not null, primary key
#  name              :string(255)
#  slug              :string(255)
#  division_class_id :integer
#  inserted_at       :datetime         not null
#  updated_at        :datetime         not null
#  created_at        :datetime
#
# Indexes
#
#  division_orders_name_index  (name) UNIQUE
#  division_orders_slug_index  (slug) UNIQUE
#

class DivisionOrder < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged

  belongs_to :division_class, optional: true # @TODO to remove
  has_many :families, dependent: :destroy
end
