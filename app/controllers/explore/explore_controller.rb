class Explore::ExploreController < ActionController::Base
  include Pagy::Backend

  layout 'application'
  before_action :generate_jwt

  def generate_jwt
    @jwt = ::Auth::JsonWebToken.new(
      user: current_user || User.find_by(email: 'guest@trefle.io'),
      origin: ENV['API_HOST'],
      expire: 10.minutes
      # ip: request.headers['X-Forwarded-For']
    )
  end

end
