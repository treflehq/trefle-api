class Explore::ExploreController < ActionController::Base
  include Pagy::Backend

  layout 'application'
  before_action :generate_jwt
  before_action :set_meta

  rescue_from Pagy::OverflowError, with: :render_page_not_found
  rescue_from Pagy::VariableError, with: :render_page_not_found

  def generate_jwt
    @jwt = ::Auth::JsonWebToken.new(
      user: current_user || User.find_by(email: 'guest@trefle.io'),
      origin: ENV['API_HOST'],
      expire: 10.minutes
      # ip: request.headers['X-Forwarded-For']
    )
  end

  def set_meta
    set_meta_tags open_search: {
      title: 'Open Search',
      href: '/opensearch.xml'
    }
  end

  # An out-of-range or malformed :page (Pagy::OverflowError / Pagy::VariableError) is a
  # 404, not a 500 — same treatment the API side already gives it in Api::ApiController.
  def render_page_not_found
    render file: Rails.public_path.join('404.html'), status: :not_found, layout: false
  end

end
