module Api
  class ApiController < ActionController::API
    rescue_from ActiveRecord::RecordInvalid, with: :render_unprocessable_record_response
    rescue_from ActionController::ParameterMissing, with: :render_unprocessable_entity_response
    rescue_from ActiveRecord::RecordNotFound, with: :render_not_found_response
    rescue_from Pagy::OverflowError, with: :render_page_overflow_response
    rescue_from Pagy::VariableError, with: :render_page_overflow_response

    include ActionController::MimeResponds
    include CollectionRenderers
    include Pagy::Backend

    before_action :cors_set_access_control_headers
    before_action :authorize_request!
    before_action :set_raven_context
    before_action :log_request
    after_action :cors_set_access_control_headers

    respond_to :json

    def cors_preflight_check
      return unless request.method == 'OPTIONS'

      cors_set_access_control_headers
      render text: '', content_type: 'text/plain'
    end

    protected

    def log_request
      puts "🚠 Request by [#{@current_user&.email || 'anonymous'}]"
      UserQuery.mark!(@current_user&.id) if @current_user
    end

    def authorize_request!
      @token = token_from_request

      if @token.blank?
        render_unauthorized('An access token is required to access this resource. See https://trefle.io')
      else
        begin
          user = user_from_token(@token)
          # TODO: we don't want to update current_sign_in_at on each request
          # sign_in user, store: false if user

          check_jwt! if @jwt

          @current_user = user
        rescue ActiveRecord::RecordNotFound => e
          render_unauthorized('Invalid access token') && (return)
        rescue JWT::DecodeError => e
          render_unauthorized(e.message) && (return)
        end
      end
    end

    def set_raven_context
      Raven.user_context(
        id: @current_user&.id,
        email: @current_user&.email,
        username: @current_user&.name,
        jwt: @jwt
      )
      Raven.extra_context(params: params.to_unsafe_h, url: request.url)
    end

    # Setup custom CORS for JWT client tokens
    def cors_set_access_control_headers
      if @jwt # rubocop:todo Style/GuardClause
        headers['Access-Control-Allow-Origin'] = @jwt[:origin]
        headers['Access-Control-Allow-Methods'] = 'POST, GET, OPTIONS'
        headers['Access-Control-Allow-Headers'] = '*'
        headers['Access-Control-Max-Age'] = '1728000'
      end
    end

    def token_from_request
      token = params[:token]

      if token.blank?
        auth_header = request.headers['Authorization']
        token = auth_header.strip.split(' ')&.last if auth_header
      end

      token
    end

    # def cached_json(collection, key = nil, last_modified = nil, delay = 5.days)
    #   expires_in delay

    #   end_key = (key || "trefle/#{params[:action] || 'gen'}/#{collection.cache_key}-#{collection.cache_version}")

    #   last_modified ||= collection.respond_to?(:updated_at) ? collection.updated_at : collection.maximum(:updated_at)
    #     serialized_collection = Rails.cache.fetch(end_key) do
    #       yield
    #     end
    #     render(json: serialized_collection) && return
    #   end
    # end

    def user_from_token(token)
      token.length > 43 ? user_from_jwt_token(token) : user_from_regular_token(token)
    end

    def user_from_regular_token(token)
      User.find_by_token!(token)
    end

    def user_from_jwt_token(token)
      puts 'JWT !'
      @jwt = ::Auth::JsonWebToken.decode(token)
      puts @jwt.inspect
      User.find(@jwt[:user_id])
    end

    def check_jwt!
      origin = @jwt['origin']
      ip = @jwt['ip'] ? IPAddr.new(@jwt['ip']) : nil
      exp = @jwt['exp']

      client_ip = IPAddr.new(request.remote_ip || request.remote_addr)
      client_origin = request.headers['origin']

      puts "origin = #{request.headers['origin']}"
      puts "request.remote_ip = #{request.remote_ip}"
      puts "request.env['HTTP_X_FORWARDED_FOR'] = #{request.env['HTTP_X_FORWARDED_FOR']}"
      puts "request.remote_addr = #{request.remote_addr}"
      puts "request.env['REMOTE_ADDR'] = #{request.env['REMOTE_ADDR']}"

      render_unauthorized('Token expired') && return if Time.zone.now.to_i > exp.to_i

      render_unauthorized("Origin (#{origin}) don\'t match #{client_origin}") && return if client_origin && origin != client_origin

      render_unauthorized("IP address (#{client_ip}) is not allowed (expecting #{ip})") && return if ip && ip != client_ip
    end

    def render_error(message, status)
      render(json: { error: true, message: message }, status: status)
    end

    def render_unprocessable_record_response(exception)
      render_error(exception.record.errors, :unprocessable_entity)
    end

    def render_unprocessable_entity_response(exception)
      render_error(exception.message, :unprocessable_entity)
    end

    def render_not_found_response(exception)
      render_error(exception.message.gsub(' with friendly id', ''), :not_found)
    end

    def render_page_overflow_response(exception)
      render_error(exception.message, :not_found)
    end

    def apply_filters(collection, filterable_fields)
      if params[:filter]&.is_a?(ActionController::Parameters)
        collection.filter_with(params[:filter].permit(filterable_fields).slice(*filterable_fields))
      else
        collection
      end
    end

    def apply_filters_not(collection, filterable_fields)
      if params[:filter_not]&.is_a?(ActionController::Parameters)
        collection.filter_not_with(params[:filter_not].permit(filterable_fields).slice(*filterable_fields))
      else
        collection
      end
    end

    def apply_sort(collection, orderable_fields, default_sort:)
      if params[:order]&.is_a?(ActionController::Parameters)
        collection.sort_with(params[:order].permit(orderable_fields).slice(*orderable_fields))
      else
        collection.order(default_sort)
      end
    end

    def apply_range(collection, rangeable_fields)
      if params[:range]&.is_a?(ActionController::Parameters)
        collection.range_with(params[:range].permit(rangeable_fields).slice(*rangeable_fields))
      else
        collection
      end
    end

    def apply_search(collection)
      if params[:q]
        collection.search(params[:q])
      else
        collection
      end
    end

  end
end
