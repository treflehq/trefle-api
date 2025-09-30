require 'net/http'
require 'uri'
require 'json'

class GithubSponsorshipService
  # Le 'login' est celui de l'organisation ou du compte qui reçoit les sponsors
  SPONSORED_ACCOUNT_LOGIN = 'treflehq'
  GITHUB_API_URL = URI.parse('https://api.github.com/graphql')
  # Tu dois générer un Personal Access Token (PAT) avec les droits `read:user` et `read:org`
  GITHUB_TOKEN = ENV['GITHUB_API_TOKEN']

  def self.is_user_sponsoring?(user_github_login)
    query = <<~GRAPHQL
      query {
        user(login: "#{user_github_login}") {
          sponsorshipForViewerAsSponsorable(sponsorableLogin: "#{SPONSORED_ACCOUNT_LOGIN}") {
            tier {
              name
              monthlyPriceInDollars
            }
          }
        }
      }
    GRAPHQL

    http = Net::HTTP.new(GITHUB_API_URL.host, GITHUB_API_URL.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(GITHUB_API_URL.request_uri)
    request['Authorization'] = "Bearer #{GITHUB_TOKEN}"
    request['Content-Type'] = 'application/json'
    request.body = { query: query }.to_json

    response = http.request(request)
    data = JSON.parse(response.body)

    # Navigue dans la structure de la réponse GraphQL
    sponsorship = data.dig('data', 'user', 'sponsorshipForViewerAsSponsorable')

    return nil unless sponsorship # L'utilisateur n'est pas un sponsor

    sponsorship['tier'] # Retourne les infos du tier, ex: {"name"=>"Pro", "monthlyPriceInDollars"=>10}
  end
end
