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
require 'rails_helper'

RSpec.describe CommonName, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
