class HomeController < ApplicationController

  def index
    @page_title       = 'The plants API'
    @page_description = 'Trefle is a botanical API and data source.'
    @page_keywords    = 'API, Botanical, Plants, Species, Data'

    # Backs the redesigned home page (#305): taxonomic ranks, field
    # completeness shares, and recent correction activity.
    @home_stats = HomeStatsPresenter.new

    @jwt = ::Auth::JsonWebToken.new(
      user: User.find_by(email: 'guest@trefle.io'),
      origin: ENV['API_HOST'],
      expire: 10.minutes
      # ip: request.headers['X-Forwarded-For']
    )
  end

  def about
    @page_title       = 'About'
    @page_description = 'Trefle is a botanical API and data source.'
    @page_keywords    = 'API, Botanical, Plants, Species, Data'
  end

end
