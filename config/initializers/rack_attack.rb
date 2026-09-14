class Rack::Attack

  REQUEST_PER_IP_THROTTLE = 'request per ip'.freeze

  # `req.params` is `GET.merge(POST)`, so reading it here used to force a
  # full parse of the request body on every request this safelist/throttle
  # evaluates -- before any throttling has happened, on unthrottled traffic.
  # A malformed multipart body then raised out of Rack::Request#POST and
  # out of the whole stack as a 500 (#331). A token was never documented as
  # acceptable in a POST body (`POST /api/auth/claim`'s `token` security
  # scheme is `apiKey, in: query` -- see spec/swagger_helper.rb), so read it
  # from the query string only; `req.GET` never touches the body.
  def self.token(req)
    [
      req.env['HTTP_AUTHORIZATION'].to_s.downcase.gsub(/bearer /, ''),
      req.GET['token'].to_s.downcase.gsub(/\s+/, '')
    ].reject(&:blank?).first
  end

  # Same envelope as Api::ApiController#render_error -- these responses are
  # built by Rack middleware, before any controller runs, so they can't
  # reuse the helper directly (#216). Shared by throttled_responder (429s,
  # below) and RateLimitHeadersMiddleware's malformed-request 400s (#331).
  def self.error_envelope(code, message)
    {
      error: true,
      code: code,
      message: message,
      messages: message
    }.to_json
  end

  # Builds the RateLimit-* headers (draft IETF RateLimit-Limit /
  # RateLimit-Remaining / RateLimit-Reset convention -- documented alongside
  # the getting-started guide's rate limiting section). Shared by the
  # throttled_responder below (429s) and by RateLimitHeadersMiddleware
  # (every other /api response).
  def self.rate_limit_headers(match_data)
    now = match_data[:epoch_time]
    reset_at = now + (match_data[:period] - now % match_data[:period])
    remaining = [match_data[:limit] - match_data[:count], 0].max

    {
      'RateLimit-Limit' => match_data[:limit].to_s,
      'RateLimit-Remaining' => remaining.to_s,
      'RateLimit-Reset' => reset_at.to_s
    }
  end
end

Rack::Attack.safelist('allowed users') do |request|
  # Requests are allowed if the return value is truthy
  Rack::Attack.token(request)&.starts_with?('unl-')
end

limit_proc = proc {|req| Rack::Attack.token(req)&.starts_with?('spo-') ? 600 : 60 }

Rack::Attack.throttle(Rack::Attack::REQUEST_PER_IP_THROTTLE, limit: limit_proc, period: 60) do |req|
  [req.ip, Rack::Attack.token(req)].join('-') if req.path.starts_with?('/api')
end

Rack::Attack.cache.store = ActiveSupport::Cache::RedisCacheStore.new(url: ENV['REDIS_URL'] || 'redis://127.0.0.1:6379', expires_in: 480.minutes)

Rack::Attack.throttled_response_retry_after_header = true

Rack::Attack.throttled_responder = lambda do |request|
  match_data = request.env['rack.attack.match_data']
  is_sponsor = Rack::Attack.token(request)&.starts_with?('spo-')
  message = is_sponsor ? 'Too many requests, please slow down' : 'Too many requests. Please visit https://trefle.io/about#support to learn how to increase your limit.'

  headers = { 'Content-Type' => 'application/json' }.merge(Rack::Attack.rate_limit_headers(match_data))

  [429, headers, [Rack::Attack.error_envelope('too_many_requests', message)]]
end

# Surfaces the same RateLimit-* headers on every other /api response, not
# just the throttled ones, so well-behaved clients can self-regulate before
# hitting a 429. Rack::Attack annotates env['rack.attack.throttle_data'] for
# every request it evaluates against a throttle rule, whether or not that
# request ends up throttled -- this middleware reads that back.
#
# It is also where three unrelated malformed-request 500s get turned into
# 400s (#331). All three are a client-controlled header or body a downstream
# Rack/Rails internal raises on instead of handling:
#
#   - ActionDispatch::RemoteIp::IpSpoofAttackError: a request carrying both
#     Client-IP and X-Forwarded-For, disagreeing. Raised from
#     Rails::Rack::Logger#call_app, logging the request line *before*
#     calling into the rest of the stack -- it never reaches
#     ActionDispatch::ShowExceptions, so it must be rescued here.
#   - Rack::Multipart::EmptyContentError: a truncated/empty multipart body.
#     Raised from deep inside Rack::Attack's own safelist/throttle
#     evaluation (`req.POST`) -- ShowExceptions *does* wrap that call, so it
#     rescues this one already and renders a generic 500. It records the
#     exception on `env['action_dispatch.exception']` before doing so,
#     which is what lets us catch it here too and downgrade it to 400.
#   - Encoding::CompatibilityError (a kind of EncodingError): a form field
#     name that isn't valid UTF-8. Raised from Rack::MethodOverride, which
#     runs *before* calling the rest of the stack (so, like the spoof
#     error, before ShowExceptions can see it) and only rescues a handful
#     of other error classes itself.
#
# `unshift`ed to the very top of the middleware stack (below), so it wraps
# everything, regardless of which of the two paths above a given exception
# takes to get here.
#
# Defined inline (rather than under lib/, which is eager_load_paths-only
# here) because config/initializers runs before Zeitwerk's main autoloader
# is set up; an autoloadable constant referenced this early raises
# NameError.
class RateLimitHeadersMiddleware
  MALFORMED_REQUEST_ERRORS = [
    ActionDispatch::RemoteIp::IpSpoofAttackError,
    Rack::Multipart::EmptyContentError,
    EncodingError
  ].freeze

  def initialize(app)
    @app = app
  end

  def call(env)
    status, headers, body = @app.call(env)

    if (exception = env['action_dispatch.exception']) && malformed_request_error?(exception)
      return malformed_request_response(env)
    end

    match_data = env.dig('rack.attack.throttle_data', Rack::Attack::REQUEST_PER_IP_THROTTLE)
    headers.merge!(Rack::Attack.rate_limit_headers(match_data)) if match_data

    [status, headers, body]
  rescue *MALFORMED_REQUEST_ERRORS
    malformed_request_response(env)
  end

  private

  def malformed_request_error?(exception)
    MALFORMED_REQUEST_ERRORS.any? {|klass| exception.is_a?(klass) }
  end

  # The documented /api envelope (see Rack::Attack.error_envelope above)
  # for /api paths; a plain text 400 everywhere else.
  def malformed_request_response(env)
    if env['PATH_INFO'].to_s.start_with?('/api')
      message = 'The request could not be understood by the server.'
      [400, { 'Content-Type' => 'application/json' }, [Rack::Attack.error_envelope('bad_request', message)]]
    else
      [400, { 'Content-Type' => 'text/plain' }, ['Bad Request']]
    end
  end
end

# `unshift` so this always wraps Rack::Attack (and sees its 429s),
# regardless of whether this initializer or rack-attack's own railtie
# ("rack-attack.middleware") runs first.
Rails.application.config.middleware.unshift(RateLimitHeadersMiddleware)
