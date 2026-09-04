module Api
  class ApiController < ActionController::API
    class UnknownQueryKeyError < StandardError; end

    # rescue_from handlers are searched most-specific-last-declared-first (see
    # ActiveSupport::Rescuable#find_rescue_handler): it reverses the
    # declaration list and takes the first class match. StandardError has to
    # be declared FIRST so every more specific rescue below still wins; if it
    # were declared last it would shadow all of them.
    rescue_from StandardError, with: :render_internal_server_error_response
    # A malformed request body (e.g. invalid JSON with a JSON content type)
    # used to bubble past the controller and surface as an HTML error page
    # instead of the API envelope (#126).
    rescue_from ActionDispatch::Http::Parameters::ParseError, with: :render_malformed_request_response
    rescue_from ActionController::BadRequest, with: :render_bad_request_response
    rescue_from UnknownQueryKeyError, with: :render_unknown_query_key_response
    rescue_from ActiveRecord::RecordInvalid, with: :render_unprocessable_record_response
    rescue_from ActionController::ParameterMissing, with: :render_unprocessable_entity_response
    rescue_from ActiveRecord::RecordNotFound, with: :render_not_found_response
    rescue_from Pagy::OverflowError, with: :render_page_overflow_response
    rescue_from Pagy::VariableError, with: :render_page_overflow_response

    include ActionController::MimeResponds
    include CollectionRenderers
    include Pagy::Backend

    before_action :authorize_request!, except: [:cors_preflight_check]
    before_action :set_sentry_context
    before_action :log_request
    after_action :cors_set_access_control_headers

    respond_to :json

    def cors_preflight_check
      return unless request.method == 'OPTIONS'

      Rails.logger.debug('[cors_preflight_check]')
      headers['Access-Control-Allow-Origin'] = request.headers['origin']
      headers['Access-Control-Allow-Methods'] = 'POST, GET, OPTIONS'
      headers['Access-Control-Allow-Headers'] = '*'
      headers['Access-Control-Max-Age'] = '1728000'
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

          check_jwt! if @jwt

          @current_user = user
        rescue ActiveRecord::RecordNotFound
          render_unauthorized('Invalid access token') && (return)
        rescue JWT::DecodeError => e
          render_unauthorized(e.message) && (return)
        end
      end
    end

    def set_sentry_context
      Sentry.set_user(
        id: @current_user&.id,
        email: @current_user&.email,
        username: @current_user&.name,
        jwt: @jwt
      )
      Sentry.set_tags(url: request.url)
    end

    # Setup custom CORS for JWT client tokens
    def cors_set_access_control_headers
      Rails.logger.debug("[cors_set_access_control_headers] #{@jwt && @jwt[:origin]}")
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
      token.length > 48 ? user_from_jwt_token(token) : user_from_regular_token(token)
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

      puts "origin = #{origin}"
      puts "client_origin = #{request.headers['origin']}"
      puts "request.remote_ip = #{request.remote_ip}"
      puts "request.env['HTTP_X_FORWARDED_FOR'] = #{request.env['HTTP_X_FORWARDED_FOR']}"
      puts "request.remote_addr = #{request.remote_addr}"
      puts "request.env['REMOTE_ADDR'] = #{request.env['REMOTE_ADDR']}"

      render_unauthorized('Token expired') && return if Time.zone.now.to_i > exp.to_i

      render_unauthorized("Origin (#{origin}) don\'t match #{client_origin}") && return if client_origin && origin != client_origin

      render_unauthorized("IP address (#{client_ip}) is not allowed (expecting #{ip})") && return if ip && ip != client_ip
    end

    # The single envelope documented for every /api error response:
    # `{ error: true, code:, message:, messages:, details: }`, loosely
    # inspired by RFC 9457 (without adopting its media type). `code` is the
    # Rails status symbol (e.g. "not_found") so clients can switch on it
    # without parsing prose. `messages` duplicates `message` for one
    # deprecation cycle -- existing clients (mobile/third-party) read that
    # key today (#216).
    def render_error(message, status, details: nil)
      render(json: {
        error: true,
        code: error_code_for(status),
        message: message,
        messages: message,
        details: details
      }.compact, status: status)
    end

    def render_unauthorized(message)
      render_error(message, :unauthorized)
    end

    def render_unprocessable_record_response(exception)
      render_error(exception.record.errors, :unprocessable_entity)
    end

    def render_unprocessable_entity_response(exception)
      render_error(exception.message, :unprocessable_entity)
    end

    def render_bad_request_response(exception)
      render_error(exception.message, :unprocessable_entity)
    end

    def render_unknown_query_key_response(exception)
      render_error(exception.message, :bad_request)
    end

    def render_not_found_response(exception)
      render_error(exception.message.gsub(' with friendly id', ''), :not_found)
    end

    def render_page_overflow_response(exception)
      render_error(exception.message, :not_found)
    end

    def render_malformed_request_response(_exception)
      render_error('The request body could not be parsed. Check that it is valid JSON.', :bad_request)
    end

    def render_internal_server_error_response(exception)
      Rails.logger.error("[render_internal_server_error_response] #{exception.class}: #{exception.message}")
      # rescue_from handles the exception before it escapes the controller, so it never reaches
      # Sentry::Rails::CaptureExceptions (the Rack middleware that auto-reports uncaught exceptions).
      # Report it explicitly or it goes dark.
      Sentry.capture_exception(exception)
      render_error('An unexpected error occurred. Please contact us if it persists. See https://trefle.io', :internal_server_error)
    end

    def error_code_for(status)
      return status.to_s if status.is_a?(Symbol)

      Rack::Utils::SYMBOL_TO_STATUS_CODE.invert[status.to_i]&.to_s || status.to_s
    end

    def apply_filters(collection, filterable_fields)
      if params[:filter].is_a?(ActionController::Parameters)
        collection.filter_with(permit_known_query_keys(:filter, filterable_fields))
      else
        collection
      end
    end

    # @TODO ugly one
    # Turn query params into elasticsearch query
    def search_params(filter_not_fields: [], filter_fields: [], order_fields: [], range_fields: [])
      where = {}
      order = nil
      if params[:filter_not].is_a?(ActionController::Parameters)
        params[:filter_not].permit(filter_not_fields).slice(*filter_not_fields).each do |field, value|
          where[field] ||= {}
          where[field][:not] = value&.split(',')&.map {|e| e.blank? || e == 'null' ? nil : e }
        end
      end
      if params[:filter].is_a?(ActionController::Parameters)
        params[:filter].permit(filter_fields).slice(*filter_fields).each do |field, value|
          where[field] = value.split(',')
        end
      end
      if params[:range].is_a?(ActionController::Parameters)
        params[:range].permit(range_fields).slice(*range_fields).each do |field, value|
          min, max = value.split(',')
          where[field] ||= {}
          where[field][:gte] = min if min.present?
          where[field][:lte] = max if max.present?
        end
      end
      order = params[:order].permit(order_fields).slice(*order_fields).to_unsafe_hash if params[:order].is_a?(ActionController::Parameters)
      {
        where: where,
        order: order
      }
    end

    def apply_filters_not(collection, filterable_fields)
      if params[:filter_not].is_a?(ActionController::Parameters)
        collection.filter_not_with(permit_known_query_keys(:filter_not, filterable_fields))
      else
        collection
      end
    end

    def apply_sort(collection, orderable_fields, default_sort:)
      if params[:order].is_a?(ActionController::Parameters)
        collection.sort_with(permit_known_query_keys(:order, orderable_fields))
      else
        collection.order(default_sort)
      end
    end

    def apply_range(collection, rangeable_fields)
      if params[:range].is_a?(ActionController::Parameters)
        collection.range_with(permit_known_query_keys(:range, rangeable_fields))
      else
        collection
      end
    end

    def apply_search(collection)
      if params[:q]
        collection.database_search(params[:q])
      else
        collection
      end
    end

    # Raises UnknownQueryKeyError (rendered as 400) when `params[param_name]`
    # contains a key outside `allowed_fields`, instead of silently dropping it
    # like `permit`/`slice` would. Callers get valid keys back untouched.
    def permit_known_query_keys(param_name, allowed_fields)
      provided_params = params[param_name]
      unknown_keys = provided_params.keys.map(&:to_s) - allowed_fields.map(&:to_s)

      if unknown_keys.any?
        raise UnknownQueryKeyError, "Unknown #{param_name} key#{'s' if unknown_keys.size > 1}: #{unknown_keys.join(', ')}. " \
          "Valid #{param_name} keys are: #{allowed_fields.join(', ')}."
      end

      provided_params.permit(allowed_fields).slice(*allowed_fields)
    end

  end
end
