# The version of the data Trefle serves, derived from the data journal
# (DataRun) rather than maintained by hand: a researcher citing Trefle needs
# to say *which* state of the data they used, and only the runs that wrote
# to the data know when it last moved.
#
# The version is the UTC date of the latest finished, non dry-run DataRun,
# as YYYY.MM.DD; when several runs finished that day, the later ones get an
# ordinal suffix (2026.10.13, 2026.10.13.2, ...). A version string therefore
# never changes meaning once published: a run finishing later the same day
# produces a new string, it does not rewrite the previous one.
#
# Failed runs count: a run that died half-way may still have written, and the
# version has to move when the data may have. Dry runs never do.
#
# What it does not cover: community corrections accepted one by one between
# two runs (they are journaled as RecordCorrection, not as DataRun). The
# /citation page asks for an access date alongside the version for that
# reason.
#
# Read on every API response (meta.dataset_version, X-Trefle-Data-Version),
# so the lookup is kept in the cache store and, on top of it, memoized in the
# process for a short while: one memcached round trip per process per
# PROCESS_TTL, one indexed query per CACHE_TTL.
class DatasetVersion

  CACHE_KEY = 'dataset_version/v1'.freeze
  CACHE_TTL = 5.minutes
  PROCESS_TTL = 30.seconds

  attr_reader :version, :released_at, :data_run_id

  def initialize(version:, released_at:, data_run_id:)
    @version = version
    @released_at = released_at
    @data_run_id = data_run_id
  end

  # Run kinds that read the data without writing it: an export of version
  # 2026.10.13 must not itself produce version 2026.10.13.2.
  READ_ONLY_KINDS = %w[export audit].freeze

  # The runs that may have written to the data.
  def self.runs
    DataRun.where(dry_run: false).where.not(finished_at: nil).where.not(kind: READ_ONLY_KINDS)
  end

  # The DatasetVersion of the current data, nil when no run was ever
  # journaled (a fresh database).
  def self.current
    memo = @memo
    return memo[:value] if memo && memo[:at] > PROCESS_TTL.ago

    value = Rails.cache.fetch(CACHE_KEY, expires_in: CACHE_TTL) { compute&.to_h }
    value = from_h(value)
    @memo = { value: value, at: Time.current }
    value
  end

  # The version string alone, nil when there is none.
  def self.current_version
    current&.version
  end

  # Forget the memoized and cached value (specs, and after a run finishes
  # when the caller wants the new version visible at once).
  def self.reset!
    @memo = nil
    Rails.cache.delete(CACHE_KEY)
  end

  def self.compute
    run = runs.order(finished_at: :desc, id: :desc).first
    run && for_run(run)
  end

  # The version a given run produced.
  def self.for_run(run)
    finished = run.finished_at.utc
    day = finished.beginning_of_day..finished
    ordinal = runs.where(finished_at: day).where('finished_at < ? OR (finished_at = ? AND id <= ?)', finished, finished, run.id).count
    version = finished.strftime('%Y.%m.%d')
    version = "#{version}.#{ordinal}" if ordinal > 1

    new(version: version, released_at: run.finished_at, data_run_id: run.id)
  end

  # The versions the most recent runs produced, newest first, as
  # [run, DatasetVersion] pairs: the public changelog. Ordinals are worked
  # out in Ruby over the days involved instead of one query per run.
  def self.history(limit: 100)
    recent = runs.order(finished_at: :desc, id: :desc).limit(limit).to_a
    return [] if recent.empty?

    ordinals = day_ordinals(recent.last.finished_at.utc.beginning_of_day)

    recent.map do |run|
      finished = run.finished_at.utc
      version = finished.strftime('%Y.%m.%d')
      version = "#{version}.#{ordinals[run.id]}" if ordinals[run.id].to_i > 1
      [run, new(version: version, released_at: run.finished_at, data_run_id: run.id)]
    end
  end

  # run id => its rank among the runs of its UTC day, for the runs since
  # `since`.
  def self.day_ordinals(since)
    rows = runs.where(finished_at: since..).order(:finished_at, :id).pluck(:id, :finished_at)
    by_day = rows.group_by {|_id, finished_at| finished_at.utc.to_date }
    by_day.values.flat_map {|day_runs| day_runs.each_with_index.map {|(id, _), index| [id, index + 1] } }.to_h
  end

  def self.from_h(hash)
    return nil if hash.blank?

    hash = hash.symbolize_keys
    new(version: hash[:version], released_at: hash[:released_at], data_run_id: hash[:data_run_id])
  end

  def to_h
    { version: version, released_at: released_at, data_run_id: data_run_id }
  end

end
