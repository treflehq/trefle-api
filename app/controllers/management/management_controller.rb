require 'colorize'
require 'fileutils'

class Management::ManagementController < ActionController::Base
  include Pagy::Backend

  skip_before_action :verify_authenticity_token
  before_action :check_admin
  before_action :cors
  before_action :debug_user_agent
  layout 'management/layouts/application'
  default_form_builder BulmaFormBuilder

  def check_admin
    redirect_to root_path status: 401, notice: 'Unauthorized' unless current_user&.admin?
  end

  def cors
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Allow-Methods'] = 'POST, PUT, DELETE, GET, OPTIONS'
    headers['Access-Control-Request-Method'] = '*'
    headers['Access-Control-Allow-Headers'] = 'Origin, X-Requested-With, Content-Type, Accept, Authorization'
  end

  def debug_user_agent
    logger.warn '  ========================================  '
    logger.warn "  Request from #{request.remote_ip.green}"
    logger.warn "  -> origin = #{request.headers['origin']}"
    logger.warn "  -> request.remote_ip = #{request.remote_ip}"
    logger.warn "  -> request.env['HTTP_X_FORWARDED_FOR'] = #{request.env['HTTP_X_FORWARDED_FOR']}"
    logger.warn "  -> request.env['X-Forwarded-For'] = #{request.env['X-Forwarded-For']}"
    logger.warn "  -> request.remote_addr = #{request.remote_addr}"
    logger.warn "  -> request.env['REMOTE_ADDR'] = #{request.env['REMOTE_ADDR']}"

    logger.warn "  Subdomains #{request.subdomains.try(:join, ' + ').try(:green)}"
    logger.warn "  Locale is #{I18n.locale.to_s.green}"
    logger.warn "  User-agent #{request.user_agent.green}\n"
    logger.warn '  ========================================  '
  end

end
