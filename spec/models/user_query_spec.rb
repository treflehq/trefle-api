# == Schema Information
#
# Table name: user_queries
#
#  id         :integer          not null, primary key
#  user_id    :integer          not null
#  controller :string
#  action     :string
#  counter    :integer
#  time       :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_user_queries_on_user_id  (user_id)
#

require 'rails_helper'

RSpec.describe UserQuery, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
