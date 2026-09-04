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

class UserQuery < ApplicationRecord

  KEY_PREFIX = 'api_counter'.freeze
  REDIS_POOL = ConnectionPool.new(size: 5) { Redis.new(url: ENV['REDIS_URL'] || 'redis://127.0.0.1:6379') }

  belongs_to :user, optional: true

  scope :current, -> { where(time: UserQuery.time_key) }
  scope :for_time, ->(dt) { where(time: dt) }

  def datetime
    self.class.convert_datetime(time)
  end

  # Class methods

  def self.convert_datetime(time)
    DateTime.strptime(time.to_s, '%y%m%d%H')
  end

  def self.total_for_hour
    UserQuery.where(time: time_key)
  end

  def self.persist_all_to_database!
    REDIS_POOL.with do |conn|
      conn.scan_each(match: "#{KEY_PREFIX}:#{time_key}:*").each do |key|
        _k, time, user_id = key.split(':')
        counter = conn.get(key)
        conn.del(key)
        # Counters can outlive their user (deleted account): dropping
        # them beats crashing the whole flush on the FK constraint.
        next unless User.exists?(user_id)

        q = UserQuery.where(user_id: user_id, time: time).first_or_create
        q.update(counter: (q.counter || 0) + counter.to_i)
      end
    end
  end

  def self.clean_for!(uid)
    REDIS_POOL.with do |conn|
      conn.scan_each(match: "#{KEY_PREFIX}:*:#{uid}").each do |key|
        conn.del(key)
      end
    end
  end

  def self.clean_all!
    REDIS_POOL.with do |conn|
      conn.scan_each(match: "#{KEY_PREFIX}:*").each do |key|
        conn.del(key)
      end
    end
  end

  def self.mark!(uid)
    REDIS_POOL.with do |conn|
      conn.pipelined do
        conn.incr full_key(uid)
        conn.expire full_key(uid), 6.hours
      end
    end
  end

  def self.time_key
    Time.zone.now.strftime('%y%m%d%H')
  end

  def self.full_key(uid)
    "#{KEY_PREFIX}:#{time_key}:#{uid}"
  end

end
