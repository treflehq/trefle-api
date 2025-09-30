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
class Genus < ApplicationRecord
  self.table_name = 'genuses'

  include Filterable
  include Sortable

  include Scopes::Genus

  extend FriendlyId
  friendly_id :name, use: :slugged

  belongs_to :family, optional: true
  has_many :plants, dependent: :destroy
  has_many :species, dependent: :destroy
  has_many :common_names, as: :record, dependent: :destroy

end
