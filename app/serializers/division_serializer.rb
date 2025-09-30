# == Schema Information
#
# Table name: divisions
#
#  id            :bigint           not null, primary key
#  inserted_at   :datetime         not null
#  name          :string(255)
#  slug          :string(255)
#  created_at    :datetime
#  updated_at    :datetime         not null
#  subkingdom_id :bigint
#
# Indexes
#
#  divisions_name_index  (name) UNIQUE
#  divisions_slug_index  (slug) UNIQUE
#
# Foreign Keys
#
#  divisions_subkingdom_id_fkey  (subkingdom_id => subkingdoms.id)
#

class DivisionSerializer < BaseSerializer

  attributes :id, :name, :slug, :links

  has_one :subkingdom, serializer: SubkingdomSerializer

  def links
    {
      self: url_helpers.api_v1_division_path(object),
      subkingdom: url_helpers.api_v1_subkingdom_path(object.subkingdom)
    }
  end
end
