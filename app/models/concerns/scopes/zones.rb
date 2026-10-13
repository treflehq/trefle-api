module Scopes
  module Zones
    extend ActiveSupport::Concern

    included do
      # Filters
      scope :filter_by_tdwg_level, ->(tdwg_level) { where(tdwg_level: tdwg_level) }
      scope :filter_by_tdwg_code, ->(tdwg_code) { where('LOWER(tdwg_code) IN (?)', [*tdwg_code].map(&:downcase)) }

      # Ranges
      scope :range_by_tdwg_level, ->(a, b) { where(tdwg_level: ((a.to_i)...(b&.to_i || 5))) }
      scope :range_by_species_count, ->(a, b) { where(species_count: ((a.to_i)...(b&.to_i || 9_999_999_999_999))) }
      scope :range_by_species_count_cumulative, lambda {|a, b|
        where(species_count_cumulative: ((a.to_i)...(b&.to_i || 9_999_999_999_999)))
      }

      # Exact name, case- and accent-insensitive ("france", "reunion")
      scope :named, lambda {|name|
        where('unaccent(LOWER(zones.name)) = unaccent(LOWER(?))', name.to_s.strip)
      }

      # Search (`?q=`): partial match on the name, case- and accent-insensitive,
      # exact matches first, then names starting with the query, then the rest.
      # The caller appends its own sort (name by default) as a tie-breaker.
      scope :database_search, lambda {|q|
        needle = q.to_s.strip
        next where(nil) if needle.blank?

        like = sanitize_sql_like(needle)
        rank_sql = 'CASE WHEN unaccent(LOWER(zones.name)) = unaccent(LOWER(?)) THEN 0 ' \
                   'WHEN unaccent(zones.name) ILIKE unaccent(?) THEN 1 ELSE 2 END'
        rank = sanitize_sql_array([rank_sql, needle, "#{like}%"])
        where('unaccent(zones.name) ILIKE unaccent(?)', "%#{like}%").order(Arel.sql(rank))
      }
    end
  end
end
