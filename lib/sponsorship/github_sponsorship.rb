require 'net/http'
require 'uri'
require 'json'

class Sponsorship::GithubSponsorship
  # Le 'login' est celui de l'organisation ou du compte qui reçoit les sponsors
  SPONSORED_ACCOUNT_LOGIN = 'treflehq'
  GITHUB_API_URL = URI.parse('https://api.github.com/graphql')
  # Tu dois générer un Personal Access Token (PAT) avec les droits `read:user` et `read:org`
  GITHUB_TOKEN = ENV['GITHUB_API_TOKEN']

  def self.get_sponsors()
    query = <<~GRAPHQL
      query {
        organization(login: "#{SPONSORED_ACCOUNT_LOGIN}") {
          sponsorshipsAsMaintainer(first: 100, activeOnly: true) {

            nodes {
              sponsorEntity {
                # Check if it's an Organization and get its login
                ... on Organization {
                  login
                }
                # Check if it's a User and get its login
                ... on User {
                  login
                  email
                }
              }
              createdAt
              tier {
                name
                description
                monthlyPriceInDollars
              }
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

    puts response.inspect
    data = JSON.parse(response.body)

    puts data.inspect

    # Navigue dans la structure de la réponse GraphQL
    sponsorship = data.dig('data', 'organization', 'sponsorshipsAsMaintainer', 'nodes')

    return nil unless sponsorship&.any? # L'utilisateur n'est pas un sponsor

    sponsorship.map{|e| [e["sponsorEntity"]["login"], e["tier"]["monthlyPriceInDollars"]] }.to_h
  end

  def self.reassign_sponsor_status
    sponsors = get_sponsors()
    return unless sponsors

    User.where.not(sponsored_tier: nil, github_username: sponsors.keys).update_all(sponsored_tier: nil)

    sponsors.each do |github_login, tier_amount|
      puts "Adding #{github_login} with tier #{tier_amount}"
      User.find_by(github_username: github_login)&.update(sponsored_tier: tier_amount)
    end
  end

end
