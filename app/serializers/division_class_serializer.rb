# == Schema Information
#
# Table name: division_classes
#
#  id          :bigint           not null, primary key
#  inserted_at :datetime         not null
#  name        :string(255)
#  slug        :string(255)
#  created_at  :datetime
#  updated_at  :datetime         not null
#  division_id :bigint
#
# Indexes
#
#  division_classes_division_id_index  (division_id)
#  division_classes_name_index         (name) UNIQUE
#
# Foreign Keys
#
#  division_classes_division_id_fkey  (division_id => divisions.id)
#

class DivisionClassSerializer < BaseSerializer

  attributes :id, :name, :slug, :links

  has_one :division, serializer: DivisionSerializer

  def links
    {
      self: url_helpers.api_v1_division_class_path(object),
      division: object.division && url_helpers.api_v1_division_path(object.division)
    }
  end
end
