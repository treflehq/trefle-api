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
    @team_stats       = about_team_stats
  end

  private

  # Real numbers for the about page team tiles: admins maintain the platform,
  # reviewers have accepted at least one correction, contributors submitted
  # one this year. Cached: three aggregates nobody needs fresher than daily.
  def about_team_stats
    Rails.cache.fetch('about/team_stats/v1', expires_in: 1.day) do
      {
        core: User.where(admin: true).count,
        reviewers: RecordCorrection.where.not(accepted_by: nil).distinct.count(:accepted_by),
        contributors: RecordCorrection.where(created_at: Time.zone.now.beginning_of_year..)
          .where.not(user_id: nil).distinct.count(:user_id)
      }
    end
  end

end
