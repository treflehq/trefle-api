require 'httparty'
require 'colorize'

module Resolver

  class Powo

    RANK_MAP = {
      'SUBSPECIES' => 'ssp',
      'SPECIES' => 'species',
      'Species' => 'species',
      'VARIETY' => 'var',
      'Subvariety' => 'subvar',
      'SUBVARIETY' => 'subvar',
      'Form' => 'form',
      'FORM' => 'form',
      'HYBRID' => 'hybrid'
    }.freeze

    include HTTParty
    base_uri 'http://powo.science.kew.org/api/1'

    class << self

      # Will request POWO to resolve a given scientific name
      def resolve_hash(scientific_name) # rubocop:todo Metrics/PerceivedComplexity
        d = Rails.cache.read("resolver/powo/resolve_hash/#{scientific_name}")
        return JSON.parse(d)&.deep_symbolize_keys if d

        match = search_scientific_name(scientific_name)

        return unless match

        return if match[:kingdom] != 'Plantae'
        return unless match[:accepted]

        data = format_entry(match)
        Rails.cache.write("resolver/powo/resolve_hash/#{scientific_name}", data.to_json, expires_in: 12.hours)
        data
      end

      # Search for POWO exact matches
      def search_scientific_name(scientific_name)
        d = Rails.cache.read("resolver/powo/search/#{scientific_name}")
        return JSON.parse(d)&.deep_symbolize_keys if d

        r = get(
          '/search',
          query: { q: scientific_name }.compact
        )
        return unless r.ok?

        puts "[POWO] [#{scientific_name}] Adding #{r.parsed_response['totalResults']} items"
        data = r.parsed_response['results']&.filter{|e| e['accepted'] && e['rank'] != 'Genus'}&.first&.deep_symbolize_keys
        Rails.cache.write("resolver/powo/search/#{scientific_name}", data.to_json, expires_in: 12.hours)
        data
      end

      # Search on POWO from an ID
      def fetch_species(id)
        r = get("/taxonomy/#{DATASET_KEY}/#{id}")
        return unless r.ok?

        puts "[POWO] [#{id}] Fetched"
        r.parsed_response&.deep_symbolize_keys
      end

      def clean_authorship(authorship)
        return {} if authorship.nil? || authorship.blank?

        reg = /, ([1-9][0-9]{2,3})/
        if authorship.match(reg)
          year = authorship.match(reg)[1]
          author = authorship.gsub(reg, '').strip
          { author: author, year: year }
        else
          { author: authorship }
        end
      end

      # Tuen a POWO entry into a Trefle-readable entry
      def format_entry(entry)
        rank = RANK_MAP[entry[:rank]]&.to_sym
        scientific_name = ::Utils::ScientificName.format_name(entry[:name], entry[:author])
        rank = :hybrid if scientific_name&.match(/ × /) && rank == :species

        authorship = clean_authorship(entry[:authorship])
        {
          scientific_name: scientific_name,
          rank: rank,
          author: entry[:authorship],
          status: 'accepted',
          source_powo: entry[:fqId]
        }.merge(authorship).compact
      end

    end
  end
end
