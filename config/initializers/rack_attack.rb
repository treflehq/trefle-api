class Rack::Attack

  def self.token(req)
    [
      req.env['HTTP_AUTHORIZATION'].to_s.downcase.gsub(/bearer /, ''),
      req.params['token'].to_s.downcase.gsub(/\s+/, '')
    ].reject(&:blank?).first
  end

  # throttle('global/ip', limit: 500, period: 5.minute, &:ip)

  # # We will throttle the amount of suggestions people can do per ip
  # throttle('videos/ip', limit: 2, period: 20.seconds) do |req|
  #   req.ip if req.path =~ /videos(\.json)?/ && req.post?
  # end
  safelist('allowed users') do |request|
    # Requests are allowed if the return value is truthy
    token(request).starts_with?('unl-')
  end

  throttle('/api/user', limit: 120, period: 60.seconds) do |req|
    if req.path.starts_with?('/api')
      # Normalize the email, using the same logic as your authentication process, to
      # protect against rate limit bypasses.
      # pp req.env.collect {|key, val| "#{key}: #{val}"}.sort
      [req.ip, token(req)].join('-')
    end
  end

  self.throttled_response = lambda do |env|
    match_data = env['rack.attack.match_data']
    now = match_data[:epoch_time]

    headers = {
      'Content-Type' => 'application/json',
      'RateLimit-Limit' => match_data[:limit].to_s,
      'RateLimit-Remaining' => '0',
      'RateLimit-Reset' => (now + (match_data[:period] - now % match_data[:period])).to_s
    }

    [
      429,
      headers,
      [{ error: true, message: 'Too many requests, please slow down' }.to_json]
    ]
  end
end
