# Walks the public API to keep the cache warm and to notice an endpoint that
# has started failing.
#
# Replaces CacheWarmerWorker, which only fetched a handful of collection roots
# and the most-requested records — enough to warm something, not enough to
# discover that a filter raises on page 500.
#
# Every run covers the whole *shape* of the API: each collection crossed with
# each filter, order and range key it accepts. That part is bounded and is what
# catches regressions. It then takes a slice of the *depth* — deep pagination
# and individual records — resuming where the previous run stopped, because
# that part is far too large to cover in one go.
#
# Failures are reported to Sentry rather than only logged: a 500 nobody sees is
# the same as no check at all.
class ApiSweepWorker
  include Sidekiq::Worker

  sidekiq_options queue: :low, retry: false, backtrace: true

  CURSOR_KEY = 'api_sweep:cursor'.freeze
  DEFAULT_DEPTH = 250

  def perform(depth_slice = DEFAULT_DEPTH)
    token = sweep_token
    unless token
      Rails.logger.error('[ApiSweep] no unlimited token available, skipping')
      return false
    end

    cursor = read_cursor
    paths = Api::Sweep.shape_paths + Api::Sweep.depth_paths(cursor, depth_slice)
    failures = paths.filter_map {|path| failure_for(path, token) }

    write_cursor(cursor + depth_slice)
    report(paths.length, failures)

    { requested: paths.length, failed: failures.length, failures: failures }
  end

  private

  # rack-attack safelists 'unl-' tokens, so a sweep neither consumes a quota
  # nor throttles itself into false failures.
  def sweep_token
    User.where(admin: true).find_each do |user|
      return user.token if user.token&.starts_with?('unl-')
    end
    nil
  end

  def read_cursor
    Sidekiq.redis {|r| r.get(CURSOR_KEY) }.to_i
  rescue StandardError
    0
  end

  def write_cursor(value)
    Sidekiq.redis {|r| r.set(CURSOR_KEY, value) }
  rescue StandardError => e
    Rails.logger.warn("[ApiSweep] could not persist cursor: #{e.message}")
  end

  # Returns a failure description, or nil when the path answered acceptably.
  def failure_for(path, token)
    separator = path.include?('?') ? '&' : '?'
    env = Rack::MockRequest.env_for("http://localhost#{path}#{separator}token=#{token}",
                                    'HTTP_HOST' => 'localhost')
    status, _headers, body = Rails.application.call(env)
    # Rack requires the caller to close the body. Skipping it leaves the
    # per-request local cache attached to this thread, which is how an earlier
    # version appeared to warm a cache it had not written to.
    body.close if body.respond_to?(:close)

    return nil if acceptable?(status)

    { path: path, status: status }
  rescue StandardError => e
    { path: path, status: 'exception', error: "#{e.class}: #{e.message}" }
  end

  # 404 is a legitimate answer for a page past the end of a collection, and 304
  # means the cache did its job.
  def acceptable?(status)
    [200, 304, 404].include?(status)
  end

  def report(requested, failures)
    if failures.empty?
      Rails.logger.info("[ApiSweep] #{requested} paths, all healthy")
      return
    end

    Rails.logger.error("[ApiSweep] #{failures.length}/#{requested} paths failed")
    failures.first(20).each {|f| Rails.logger.error("[ApiSweep]   #{f[:status]} #{f[:path]} #{f[:error]}") }

    return unless defined?(Sentry)

    Sentry.capture_message(
      "API sweep: #{failures.length} of #{requested} paths failed",
      level: :error,
      extra: { failures: failures.first(50) }
    )
  end
end
