class Rack::Attack

  def self.token(req)
    [
      req.env['HTTP_AUTHORIZATION'].to_s.downcase.gsub(/bearer /, ''),
      req.params['token'].to_s.downcase.gsub(/\s+/, '')
    ].reject(&:blank?).first
  end
end

Rack::Attack.safelist('allowed users') do |request|
  # Requests are allowed if the return value is truthy
  Rack::Attack.token(request)&.starts_with?('unl-')
end

limit_proc = proc { |req| Rack::Attack.token(req)&.starts_with?('spo-') ? 600 : 60 }


Rack::Attack.throttle('request per ip', limit: limit_proc, period: 60) do |req|
  [req.ip, Rack::Attack.token(req)].join('-') if req.path.starts_with?('/api')
end

Rack::Attack.cache.store = ActiveSupport::Cache::RedisCacheStore.new(url: (ENV['REDIS_URL'] || 'redis://127.0.0.1:6379'), expires_in: 480.minutes)

Rack::Attack.throttled_response_retry_after_header = true

Rack::Attack.throttled_responder = lambda do |request|
  match_data = request.env['rack.attack.match_data']
  now = match_data[:epoch_time]
  is_sponsor = Rack::Attack.token(request)&.starts_with?('spo-')

  headers = {
    'Content-Type' => 'application/json',
    'RateLimit-Limit' => match_data[:limit].to_s,
    'RateLimit-Remaining' => '0',
    'RateLimit-Reset' => (now + (match_data[:period] - now % match_data[:period])).to_s
  }

  [429, headers, [
    {
      error: true,
      message: is_sponsor ? 'Too many requests, please slow down' : 'Too many requests. Please visit https://trefle.io/about#support to learn how to increase your limit.'
    }.to_json]
  ]
end
