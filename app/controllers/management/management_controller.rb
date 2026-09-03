require 'colorize'
require 'fileutils'

class Management::ManagementController < ActionController::Base
  include Pagy::Backend

  skip_before_action :verify_authenticity_token
  before_action :check_admin
  before_action :cors
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

end
