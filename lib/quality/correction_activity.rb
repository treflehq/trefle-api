module Quality
  # Corrections over time for the data quality dashboard: how many were filed,
  # accepted and rejected per period, and how large the pending backlog was at
  # the end of each one.
  #
  #   Quality::CorrectionActivity.new(days: 90).buckets
  #
  # Filing is dated by created_at, decisions by decided_at (rows decided
  # before that column existed carry their last update instead). Periods are
  # days up to two months, weeks beyond, so a chart keeps a readable number
  # of columns.
  class CorrectionActivity

    Bucket = Struct.new(:starts_on, :submitted, :accepted, :rejected, :pending, keyword_init: true)

    DAILY_UP_TO = 62

    attr_reader :days

    def initialize(days: 30)
      @days = days
    end

    def period
      days > DAILY_UP_TO ? :week : :day
    end

    def buckets
      @buckets ||= begin
        submitted = count_by(RecordCorrection.all, :created_at)
        accepted = count_by(RecordCorrection.accepted_change_status, :decided_at)
        rejected = count_by(RecordCorrection.rejected_change_status, :decided_at)
        pending = backlog_before

        submitted.keys.map do |starts_on|
          pending += submitted[starts_on] - accepted.fetch(starts_on, 0) - rejected.fetch(starts_on, 0)
          Bucket.new(starts_on: starts_on, submitted: submitted[starts_on], accepted: accepted.fetch(starts_on, 0),
                     rejected: rejected.fetch(starts_on, 0), pending: pending)
        end
      end
    end

    def totals
      {
        submitted: buckets.sum(&:submitted),
        accepted: buckets.sum(&:accepted),
        rejected: buckets.sum(&:rejected),
        pending_now: RecordCorrection.pending_change_status.count
      }
    end

    # Accepted over decided, in percent; nil when nothing was decided.
    def acceptance_rate
      decided = totals[:accepted] + totals[:rejected]
      return nil if decided.zero?

      (totals[:accepted] * 100.0 / decided).round(1)
    end

    private

    def range
      @range ||= days.days.ago.beginning_of_day..Time.current
    end

    def count_by(scope, column)
      scope.group_by_period(period, column, range: range).count.transform_keys(&:to_date)
    end

    # Corrections filed before the window and still undecided when it opened.
    def backlog_before
      start = range.first
      filed = RecordCorrection.where(created_at: ...start).count
      decided = RecordCorrection.where.not(change_status: :pending).where(decided_at: ...start).count
      filed - decided
    end

  end
end
