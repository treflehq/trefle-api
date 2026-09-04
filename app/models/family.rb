# == Schema Information
#
# Table name: families
#
#  id                :integer          not null, primary key
#  name              :string(255)
#  slug              :string(255)
#  common_name       :string(255)
#  division_order_id :integer
#  major_group_id    :integer
#  inserted_at       :datetime         not null
#  updated_at        :datetime         not null
#  created_at        :datetime
#
# Indexes
#
#  families_name_index  (name) UNIQUE
#  families_slug_index  (slug) UNIQUE
#

class Family < ApplicationRecord
  include Filterable
  include Sortable

  include Scopes::Families

  extend FriendlyId
  friendly_id :name, use: :slugged

  belongs_to :division_order, optional: true
  belongs_to :major_group, optional: true
  has_many :genus, dependent: :destroy
  has_many :common_names, as: :record, dependent: :destroy

end
