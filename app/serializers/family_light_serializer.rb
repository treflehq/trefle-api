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
#  families_division_order_id_index  (division_order_id)
#  families_major_group_id_index     (major_group_id)
#  families_name_index               (name) UNIQUE
#  families_slug_index               (slug) UNIQUE
#
# Foreign Keys
#
#  families_division_order_id_fkey  (division_order_id => division_orders.id)
#  families_major_group_id_fkey     (major_group_id => major_groups.id)
#

class FamilyLightSerializer < BaseSerializer

  attributes :id, :name, :common_name, :slug, :links

  def links
    {
      self: url_helpers.api_v1_family_path(object),
      division_order: object.division_order && url_helpers.api_v1_division_order_path(object.division_order),
      genus: url_helpers.api_v1_family_genus_index_path(object)
    }
  end
end
