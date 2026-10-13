module Scopes
  module Zones
    extend ActiveSupport::Concern

    included do
      # Filters
      scope :filter_by_tdwg_level, ->(tdwg_level) { where(tdwg_level: tdwg_level) }
      scope :filter_by_tdwg_code, ->(tdwg_code) { where('LOWER(tdwg_code) IN (?)', [*tdwg_code].map(&:downcase)) }

      # Ranges
      scope :range_by_tdwg_level, ->(min, max) { where_in_range(:tdwg_level, min, max) }
      scope :range_by_species_count, ->(min, max) { where_in_range(:species_count, min, max) }

      # Search
      scope :database_search, lambda {|q|
        where('name ILIKE ?', "%#{q}%")
      }
    end
  end
end
