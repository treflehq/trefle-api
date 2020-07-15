# == Schema Information
#
# Table name: user_queries
#
#  id         :bigint           not null, primary key
#  action     :string
#  controller :string
#  counter    :bigint
#  time       :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :bigint           not null
#
# Indexes
#
#  index_user_queries_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
require 'rails_helper'

RSpec.describe UserQuery, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
