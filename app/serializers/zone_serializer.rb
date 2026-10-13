# == Schema Information
#
# Table name: zones
#
#  id            :bigint           not null, primary key
#  feature       :string
#  name          :string           not null
#  slug          :string
#  species_count :integer          default(0), not null
#  species_count_cumulative :integer default(0), not null
#  tdwg_code     :string
#  tdwg_level    :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  parent_id     :integer
#
class ZoneSerializer < BaseSerializer
  attributes :name, :slug, :links, :tdwg_code, :tdwg_level, :species_count, :species_count_cumulative

  has_one :parent, serializer: ZoneLightSerializer
  has_many :children, serializer: ZoneLightSerializer

  # link(:self) {|o| url_helpers.api_v1_kingdom_path(o) }

  def links
    {
      self: url_helpers.api_v1_zone_path(object),
      plants: url_helpers.api_v1_zone_plants_path(object),
      species: url_helpers.api_v1_zone_species_index_path(object)
    }
  end
end
