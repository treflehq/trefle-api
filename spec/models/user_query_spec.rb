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
  before { UserQuery.clean_all! }

  describe '#datetime' do
    it 'parses the packed time key back into a datetime' do
      query = UserQuery.create!(user: create(:user), time: '26090412'.to_i)

      expect(query.datetime).to eq(DateTime.strptime('26090412', '%y%m%d%H'))
    end
  end

  describe '.total_for_hour' do
    it 'returns the queries recorded for the current hour key' do
      query = UserQuery.create!(user: create(:user), time: UserQuery.time_key)
      UserQuery.create!(user: create(:user), time: (UserQuery.time_key.to_i - 100).to_s)

      expect(UserQuery.total_for_hour).to contain_exactly(query)
    end
  end

  describe '.clean_for!' do
    it 'only removes the redis counters for the given user' do
      user = create(:user)
      other = create(:user)
      UserQuery.mark!(user.id)
      UserQuery.mark!(other.id)

      UserQuery.clean_for!(user.id)
      UserQuery.persist_all_to_database!

      expect(UserQuery.where(user_id: other.id).sum(:counter)).to eq(1)
      expect(UserQuery.where(user_id: user.id).sum(:counter)).to eq(0)
    end
  end
end
