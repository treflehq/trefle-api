# == Schema Information
#
# Table name: common_names
#
#  id          :integer          not null, primary key
#  record_type :string           not null
#  record_id   :integer          not null
#  name        :string
#  lang        :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_common_names_on_record_type_and_record_id  (record_type,record_id)
#

class CommonName < ApplicationRecord
  belongs_to :record, polymorphic: true

  validates :name, uniqueness: { scope: %i[lang record_id record_type] }
end
