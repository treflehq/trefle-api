module Api
  module Auth
    class AuthController < Api::ApiController
      before_action :authorize_request, except: :claim

      # POST /auth/claim
      def claim
        token = params.require(:token)
        origin = params.require(:origin)
        ip = params[:ip]

        @user = User.find_by_token(token)

        if @user
          token = ::Auth::JsonWebToken.new(user: @user, origin: origin, ip: ip)
          render json: { token: token.token, expiration: token.time.strftime('%m-%d-%Y %H:%M') }, status: :ok
        else
          render json: { error: 'unauthorized' }, status: :unauthorized
        end
      end

    end
  end
end
