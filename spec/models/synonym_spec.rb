# == Schema Information
#
# Table name: synonyms
#
#  id          :bigint           not null, primary key
#  author      :string
#  name        :string
#  notes       :text
#  record_type :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  record_id   :bigint           not null
#
# Indexes
#
#  index_synonyms_on_name                       (name)
#  index_synonyms_on_record_type_and_record_id  (record_type,record_id)
#
require 'rails_helper'

RSpec.describe Synonym, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
