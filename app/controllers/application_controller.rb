class ApplicationController < ActionController::Base
  protect_from_forgery with: :null_session
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :set_raven_context
  before_action :set_meta

  def configure_permitted_parameters
    added_attrs = %I[name account_type email password password_confirmation remember_me organization_name organization_url]
    devise_parameter_sanitizer.permit :sign_up, keys: added_attrs
    devise_parameter_sanitizer.permit :account_update, keys: added_attrs
  end

  def check_user
    redirect_to root_path status: 401, notice: 'Unauthorized' unless current_user
  end

  def set_raven_context
    Raven.user_context(id: current_user&.id, username: current_user&.name, email: current_user&.email) # or anything else in session
    Raven.extra_context(params: params.to_unsafe_h, url: request.url)
  end

  def set_meta
    set_meta_tags open_search: {
      title: "Open Search",
      href:  "/opensearch.xml"
    }
  end

end
