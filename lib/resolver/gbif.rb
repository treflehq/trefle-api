require 'httparty'
require 'colorize'

module Resolver
  class Gbif

    DATASET_KEY = 'd7dddbf4-2cf0-4f39-9b2a-bb099caae36c'.freeze

    RANK_MAP = {
      'SUBSPECIES' => 'ssp',
      'SPECIES' => 'species',
      'Species' => 'species',
      'Subvariety' => 'subvar',
      'VARIETY' => 'var',
      'SUBVARIETY' => 'subvar',
      'Subvariety' => 'subvar', # rubocop:todo Lint/DuplicateHashKey
      'Form' => 'form',
      'FORM' => 'form',
      'HYBRID' => 'hybrid'
    }.freeze

    include HTTParty
    base_uri 'https://www.gbif.org/api'

    class << self

      # Will request GBIF to resolve a given scientific name
      def resolve_hash(scientific_name) # rubocop:todo Metrics/PerceivedComplexity
        d = Rails.cache.read("resolver/gbif/resolve_hash/#{scientific_name}")
        return JSON.parse(d)&.deep_symbolize_keys if d

        match = search_scientific_name(scientific_name)

        return unless match

        confidence = match[:confidence]

        if confidence <= 90
          puts "Confidence is too low: #{confidence}, skipping..."
          return
        end

        puts "#{match[:taxonomicStatus]}: #{match.inspect}"

        if match[:synonym]
          puts "Synonym: #{match.inspect}"
          syn = fetch_species(match[:key])
          match = fetch_species(syn[:acceptedKey])
        else
          match = fetch_species(match[:key])
        end

        return unless match

        return if match[:kingdom] != 'Plantae'
        return if match[:taxonomicStatus] != 'ACCEPTED'

        pp match

        match[:main_species] = nil
        match[:confidence] = confidence

        if match[:speciesKey] != match[:key]
          ms = fetch_species(match[:speciesKey])
          match[:main_species] = format_entry(ms) if ms
        end

        data = format_entry(match)
        Rails.cache.write("resolver/gbif/resolve_hash/#{scientific_name}", data.to_json, expires_in: 12.hours)
        data
      end

      # Search for GBIF exact matches
      def search_scientific_name(scientific_name)
        d = Rails.cache.read("resolver/gbif/search/#{scientific_name}")
        return JSON.parse(d)&.deep_symbolize_keys if d

        r = get(
          '/omnisearch',
          query: { locale: 'en', q: scientific_name }.compact
        )
        return unless r.ok?

        puts "[GBIF] [#{scientific_name}] Adding #{r.parsed_response['speciesMatches']['count']} items"
        datas = r.parsed_response['speciesMatches']['results']

        data = datas&.reject {|e| e['rank'] == 'GENUS' }&.first&.deep_symbolize_keys
        Rails.cache.write("resolver/gbif/search/#{scientific_name}", data.to_json, expires_in: 12.hours)
        data
      end

      # Search on GBIF from an ID
      def fetch_species(id)
        r = get("/taxonomy/#{DATASET_KEY}/#{id}")
        return unless r.ok?

        puts "[GBIF] [#{id}] Fetched"
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

      # Tuen a GBIF entry into a Trefle-readable entry
      def format_entry(entry)
        rank = RANK_MAP[entry[:rank]]&.to_sym
        scientific_name = ::Utils::ScientificName.format_name(entry[:scientificName], entry[:authorship])
        rank = :hybrid if scientific_name&.match(/ × /) && rank == :species

        authorship = clean_authorship(entry[:authorship])
        pp authorship
        {
          scientific_name: scientific_name,
          rank: rank,
          author: entry[:authorship],
          genus: entry[:genus],
          bibliography: entry[:publishedIn],
          status: entry[:taxonomicStatus]&.underscore,
          main_species_scientific_name: entry[:main_species]&.dig(:scientific_name),
          source_gbif: entry[:key],
          confidence: entry[:confidence]
        }.merge(authorship).compact
      end

    end
  end
end
