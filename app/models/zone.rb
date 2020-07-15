# == Schema Information
#
# Table name: zones
#
#  id            :bigint           not null, primary key
#  feature       :string
#  name          :string           not null
#  slug          :string
#  species_count :integer          default(0), not null
#  tdwg_code     :string
#  tdwg_level    :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
class Zone < ApplicationRecord

  has_many :species_distributions, dependent: :destroy
  has_many :species, through: :species_distributions

  include Filterable
  include Sortable
  include Rangeable

  include Scopes::Zones

  extend FriendlyId
  friendly_id :name, use: :slugged

end
