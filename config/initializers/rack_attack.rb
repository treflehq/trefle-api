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

Rack::Attack.throttle('request per ip', limit: 60, period: 60.seconds) do |req|
  puts "throttle('request per ip', limit: 10, period: 60.seconds) => #{req.path}"
  if req.path.starts_with?('/api')
    # Normalize the email, using the same logic as your authentication process, to
    # protect against rate limit bypasses.
    # pp req.env.collect {|key, val| "#{key}: #{val}"}.sort

    puts "RATE ~ #{[req.ip, Rack::Attack.token(req)].join('-')}"
    [req.ip, Rack::Attack.token(req)].join('-')
  end
end

Rack::Attack.cache.store = ActiveSupport::Cache::RedisCacheStore.new(url: (ENV['REDIS_URL'] || 'redis://127.0.0.1:6379'), expires_in: 480.minutes)

Rack::Attack.throttled_response_retry_after_header = true

Rack::Attack.throttled_responder = lambda do |request|
  match_data = request.env['rack.attack.match_data']
  now = match_data[:epoch_time]

  headers = {
    'Content-Type' => 'application/json',
    'RateLimit-Limit' => match_data[:limit].to_s,
    'RateLimit-Remaining' => '0',
    'RateLimit-Reset' => (now + (match_data[:period] - now % match_data[:period])).to_s
  }

  [429, headers, [{ error: true, message: 'Too many requests, please slow down' }.to_json]]
end
