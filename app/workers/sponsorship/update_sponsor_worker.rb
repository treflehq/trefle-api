class Sponsorship::UpdateSponsorWorker
  include Sidekiq::Worker

  def perform()
    ::Sponsorship::GithubSponsorship.reassign_sponsor_status
  end
end
