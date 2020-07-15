# == Schema Information
#
# Table name: sessions
#
#  id          :bigint           not null, primary key
#  counters    :jsonb
#  ended_at    :datetime
#  inserted_at :datetime         not null
#  name        :string(255)
#  started_at  :datetime
#  updated_at  :datetime         not null
#
class Session < ApplicationRecord
end
