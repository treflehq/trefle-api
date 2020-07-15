# == Schema Information
#
# Table name: common_names
#
#  id          :bigint           not null, primary key
#  lang        :string
#  name        :string
#  record_type :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  record_id   :bigint           not null
#
# Indexes
#
#  index_common_names_on_record_type_and_record_id  (record_type,record_id)
#
class CommonName < ApplicationRecord
  belongs_to :record, polymorphic: true

  validates_uniqueness_of :name, scope: %i[lang record_id record_type]
end
