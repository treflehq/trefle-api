class Explore::ExploreController < ActionController::Base
  include Pagy::Backend
  include RequiresTermsAcceptance

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

  private

  # explore/species/_species_menu walks record.foreign_sources_plants.each { |fsp|
  # fsp.foreign_source } for every species/synonym it renders a sidebar for
  # (#363). The three entry points that render it (SpeciesController#show,
  # RecordCorrectionsController#index and #show) each reach the record a
  # different way -- Species.friendly_or_synonym!'s synonym fallback and
  # RecordCorrection#record are not relations a plain `.includes` can reach --
  # so preload in place on the already-loaded record instead.
  #
  # The species page's synonyms section (show.html.erb) walks the same chain
  # on each synonym, so that leg is preloaded too here -- even though that
  # loop is currently dead code (wrapped in a `=begin`/`=end` Ruby comment,
  # same convention as elsewhere in app/views/). Preloading it keeps this
  # helper matching what #363 asked for and costs nothing extra if the block
  # stays disabled; if it's ever re-enabled, it won't reintroduce the N+1.
  # `record` can (in principle) be a Synonym via RecordCorrection's
  # polymorphic association -- Synonym has no `synonyms` of its own, so guard
  # on the record's class instead of assuming Species.
  def preload_foreign_sources_for(record)
    return unless record

    associations = [{ foreign_sources_plants: :foreign_source }]
    associations << { synonyms: { foreign_sources_plants: :foreign_source } } if record.is_a?(Species)

    ActiveRecord::Associations::Preloader.new(records: [record], associations: associations).call
  end

end
