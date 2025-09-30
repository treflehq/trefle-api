class Auth::JsonWebToken
  SECRET_KEY = Rails.application.secrets.secret_key_base. to_s

  def self.encode(payload, exp = 24.hours.from_now)
    payload[:exp] = exp.to_i
    JWT.encode(payload, SECRET_KEY)
  end

  def self.decode(token)
    decoded = JWT.decode(token, SECRET_KEY)[0]
    HashWithIndifferentAccess.new decoded
  end

  def initialize(user:, origin:, ip: nil, expire: 24.hours)
    @time = Time.now + expire.to_i
    @token = ::Auth::JsonWebToken.encode(
      user_id: user.id,
      origin: origin,
      ip: ip,
      expire: @time
    )
  end

  attr_reader :token

  attr_reader :time
end
