class Rack::Attack

  # throttle('global/ip', limit: 500, period: 5.minute, &:ip)

  # # We will throttle the amount of suggestions people can do per ip
  # throttle('videos/ip', limit: 2, period: 20.seconds) do |req|
  #   req.ip if req.path =~ /videos(\.json)?/ && req.post?
  # end

  # self.throttled_response = lambda do |_env|
  #   [
  #     422,
  #     { 'Content-Type' => 'application/json' },
  #     [{ success: false, message: 'Too many requests' }.to_json]
  #   ]
  # end
end
