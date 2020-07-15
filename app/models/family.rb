# == Schema Information
#
# Table name: families
#
#  id                :bigint           not null, primary key
#  common_name       :string(255)
#  inserted_at       :datetime         not null
#  name              :string(255)
#  slug              :string(255)
#  created_at        :datetime
#  updated_at        :datetime         not null
#  division_order_id :bigint
#  major_group_id    :bigint
#
# Indexes
#
#  families_name_index  (name) UNIQUE
#  families_slug_index  (slug) UNIQUE
#
# Foreign Keys
#
#  families_division_order_id_fkey  (division_order_id => division_orders.id)
#  families_major_group_id_fkey     (major_group_id => major_groups.id)
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
