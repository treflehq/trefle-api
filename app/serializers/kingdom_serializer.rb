# == Schema Information
#
# Table name: kingdoms
#
#  id          :bigint           not null, primary key
#  inserted_at :datetime         not null
#  name        :string(255)
#  slug        :string(255)
#  created_at  :datetime
#  updated_at  :datetime         not null
#
# Indexes
#
#  kingdoms_name_index  (name) UNIQUE
#  kingdoms_slug_index  (slug) UNIQUE
#
class KingdomSerializer < BaseSerializer
  attributes :name, :slug, :links

  # link(:self) {|o| url_helpers.api_v1_kingdom_path(o) }

  def links
    {
      self: url_helpers.api_v1_kingdom_path(object)
    }
  end
end
