# == Schema Information
#
# Table name: sessions
#
#  id          :integer          not null, primary key
#  name        :string(255)
#  started_at  :datetime
#  ended_at    :datetime
#  counters    :jsonb
#  inserted_at :datetime         not null
#  updated_at  :datetime         not null
#

class Session < ApplicationRecord
end
