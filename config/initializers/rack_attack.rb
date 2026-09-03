class Rack::Attack

  REQUEST_PER_IP_THROTTLE = 'request per ip'.freeze

  def self.token(req)
    [
      req.env['HTTP_AUTHORIZATION'].to_s.downcase.gsub(/bearer /, ''),
      req.params['token'].to_s.downcase.gsub(/\s+/, '')
    ].reject(&:blank?).first
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

limit_proc = proc { |req| Rack::Attack.token(req)&.starts_with?('spo-') ? 600 : 60 }


Rack::Attack.throttle(Rack::Attack::REQUEST_PER_IP_THROTTLE, limit: limit_proc, period: 60) do |req|
  [req.ip, Rack::Attack.token(req)].join('-') if req.path.starts_with?('/api')
end

Rack::Attack.cache.store = ActiveSupport::Cache::RedisCacheStore.new(url: (ENV['REDIS_URL'] || 'redis://127.0.0.1:6379'), expires_in: 480.minutes)

Rack::Attack.throttled_response_retry_after_header = true

Rack::Attack.throttled_responder = lambda do |request|
  match_data = request.env['rack.attack.match_data']
  is_sponsor = Rack::Attack.token(request)&.starts_with?('spo-')

  headers = { 'Content-Type' => 'application/json' }.merge(Rack::Attack.rate_limit_headers(match_data))

  [429, headers, [
    {
      error: true,
      message: is_sponsor ? 'Too many requests, please slow down' : 'Too many requests. Please visit https://trefle.io/about#support to learn how to increase your limit.'
    }.to_json]
  ]
end

# Surfaces the same RateLimit-* headers on every other /api response, not
# just the throttled ones, so well-behaved clients can self-regulate before
# hitting a 429. Rack::Attack annotates env['rack.attack.throttle_data'] for
# every request it evaluates against a throttle rule, whether or not that
# request ends up throttled -- this middleware reads that back.
#
# Defined inline (rather than under lib/, which is eager_load_paths-only
# here) because config/initializers runs before Zeitwerk's main autoloader
# is set up; an autoloadable constant referenced this early raises
# NameError.
class RateLimitHeadersMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    status, headers, body = @app.call(env)

    match_data = env.dig('rack.attack.throttle_data', Rack::Attack::REQUEST_PER_IP_THROTTLE)
    headers.merge!(Rack::Attack.rate_limit_headers(match_data)) if match_data

    [status, headers, body]
  end
end

# `unshift` so this always wraps Rack::Attack (and sees its 429s),
# regardless of whether this initializer or rack-attack's own railtie
# ("rack-attack.middleware") runs first.
Rails.application.config.middleware.unshift(RateLimitHeadersMiddleware)
