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

class GenusSerializer < BaseSerializer

  attributes :id, :name, :slug, :links

  has_one :family, serializer: FamilySerializer

  # link(:self) {|o| url_helpers.api_v1_genus_path(o) }

  # meta do |o|
  #   { plants_count: o.plants.count }
  # end

  # has_many :plants, lazy_load_data: true, links: {
  #   self: -> (object) { url_helpers.api_v1_genus_plants_path(object) }
  # }

  def links
    {
      self: url_helpers.api_v1_genus_path(object),
      plants: url_helpers.api_v1_genus_plants_path(object),
      species: url_helpers.api_v1_genus_species_index_path(object),
      family: object.family && url_helpers.api_v1_family_path(object.family)
    }
  end
end
