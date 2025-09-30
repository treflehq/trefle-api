module Scopes
  module Zones
    extend ActiveSupport::Concern

    included do
      # Filters
      scope :filter_by_tdwg_level, ->(tdwg_level) { where(tdwg_level: tdwg_level) }
      scope :filter_by_tdwg_code, ->(tdwg_code) { where('LOWER(tdwg_code) IN (?)', [*tdwg_code].map(&:downcase)) }

      # Ranges
      scope :range_by_tdwg_level, ->(a, b) { where(tdwg_level: ((a&.to_i || 0)...(b&.to_i || 5))) }
      scope :range_by_species_count, ->(a, b) { where(species_count: ((a&.to_i || 0)...(b&.to_i || 9_999_999_999_999))) }

      # Search
      scope :database_search, lambda {|q|
        where('name ILIKE ?', "%#{q}%")
      }
    end
  end
end
