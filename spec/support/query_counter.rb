# Counts real SQL statements executed inside a block. Used to pin an N+1
# regression: assert the query count stays flat as the number of records in
# the response grows, instead of guessing at a fixed "magic number".
module QueryCounter
  IGNORED_PAYLOAD_NAMES = %w[SCHEMA CACHE].freeze
  IGNORED_SQL = /\A\s*(BEGIN|COMMIT|SAVEPOINT|RELEASE)/i

  def count_queries(&block)
    count = 0

    counter = lambda do |*, payload|
      count += 1 unless IGNORED_PAYLOAD_NAMES.include?(payload[:name]) || payload[:sql].match?(IGNORED_SQL)
    end

    ActiveSupport::Notifications.subscribed(counter, 'sql.active_record', &block)

    count
  end
end
