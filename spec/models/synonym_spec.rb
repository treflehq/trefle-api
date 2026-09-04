# == Schema Information
#
# Table name: synonyms
#
#  id          :integer          not null, primary key
#  record_type :string           not null
#  record_id   :integer          not null
#  name        :string
#  author      :string
#  notes       :text
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
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
