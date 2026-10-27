# `?page[number]=2` (JSON:API style) or `?page[]=2` reach the controller as a
# nested Parameters / an Array, which neither Pagy nor
# WithCachedCount#pagy_get_vars can read as a number: /plants answered a 500
# (Sentry: NoMethodError `to_i` for ActionController::Parameters). Refuse it
# up front, on every collection, with a 400 naming what to send instead.
module PageParam
  extend ActiveSupport::Concern

  class NestedPageParamError < StandardError; end

  included do
    before_action :reject_nested_page_param!
    rescue_from NestedPageParamError, with: :render_nested_page_param_response
  end

  private

  def reject_nested_page_param!
    page = params[:page]
    return if page.nil? || page.is_a?(String)

    shown = page.is_a?(Array) ? 'page[]' : "page[#{page.keys.first}]"
    raise NestedPageParamError, "page must be a positive integer, not a nested parameter (#{shown}); use ?page=2"
  end

  def render_nested_page_param_response(exception)
    render_error(exception.message, :bad_request)
  end
end
