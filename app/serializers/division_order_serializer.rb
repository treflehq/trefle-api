# == Schema Information
#
# Table name: division_orders
#
#  id                :bigint           not null, primary key
#  inserted_at       :datetime         not null
#  name              :string(255)
#  slug              :string(255)
#  created_at        :datetime
#  updated_at        :datetime         not null
#  division_class_id :bigint
#
# Indexes
#
#  division_orders_name_index  (name) UNIQUE
#  division_orders_slug_index  (slug) UNIQUE
#
# Foreign Keys
#
#  division_orders_division_class_id_fkey  (division_class_id => division_classes.id)
#

class DivisionOrderSerializer < BaseSerializer

  attributes :id, :name, :slug, :links

  has_one :division_class, serializer: DivisionClassSerializer

  def links
    {
      self: url_helpers.api_v1_division_order_path(object),
      division_class: object.division_class && url_helpers.api_v1_division_class_path(object.division_class)
    }
  end
end
