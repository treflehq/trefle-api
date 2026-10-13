module Api
  module Auth
    class AuthController < Api::ApiController
      # POST /api/auth/claim
      #
      # Trades the account token for a client-side JWT bound to `origin`
      # (and optionally `ip`). The account token is read like on every other
      # endpoint (Api::ApiController#token_from_request): the `token`
      # parameter, in the query string or the body, or else the
      # `Authorization: Bearer` header. It used to be read from `params`
      # only, so the bearerAuth scheme the OpenAPI document announces for
      # this operation answered 422.
      #
      # A JWT cannot claim another JWT: Api::ApiController#authorize_request!
      # accepts one, but `User.find_by_token` only knows account tokens, so a
      # client holding a JWT cannot extend it on its own.
      def claim
        origin = params.require(:origin)
        ip = params[:ip]

        @user = User.find_by_token(token_from_request)

        if @user
          jwt = ::Auth::JsonWebToken.new(user: @user, origin: origin, ip: ip)
          render json: {
            token: jwt.token,
            expires_at: jwt.time.utc.iso8601,
            # Deprecated: month-day-year, no time zone. Kept for the clients
            # that parse it; `expires_at` is the ISO 8601 UTC form.
            expiration: jwt.time.strftime('%m-%d-%Y %H:%M')
          }, status: :ok
        else
          render_unauthorized('Invalid credentials')
        end
      end
    end
  end
end
