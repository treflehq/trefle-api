# == Schema Information
#
# Table name: subkingdoms
#
#  id          :bigint           not null, primary key
#  inserted_at :datetime         not null
#  name        :string(255)
#  slug        :string(255)
#  created_at  :datetime
#  updated_at  :datetime         not null
#  kingdom_id  :bigint
#
# Indexes
#
#  subkingdoms_name_index  (name) UNIQUE
#  subkingdoms_slug_index  (slug) UNIQUE
#
# Foreign Keys
#
#  subkingdoms_kingdom_id_fkey  (kingdom_id => kingdoms.id)
#

class SubkingdomSerializer < BaseSerializer

  attributes :id, :name, :slug, :links

  has_one :kingdom, serializer: KingdomSerializer

  def links
    {
      self: url_helpers.api_v1_subkingdom_path(object),
      kingdom: url_helpers.api_v1_kingdom_path(object.kingdom)
    }
  end
end
