module Scopes
  module Zones
    extend ActiveSupport::Concern

    included do
      # Filters
      scope :filter_by_tdwg_level, ->(tdwg_level) { where(tdwg_level: tdwg_level) }
      scope :filter_by_tdwg_code, ->(tdwg_code) { where(tdwg_code: tdwg_code) }

      # Ranges
      scope :range_by_tdwg_level, ->(a, b) { where(tdwg_level: ((a&.to_i || 0)...(b&.to_i || 5))) }
      scope :range_by_species_count, ->(a, b) { where(species_count: ((a&.to_i || 0)...(b&.to_i || 9_999_999_999_999))) }

      # Search
      scope :search, lambda {|q|
        where('name ILIKE ?', "%#{q}%")
      }
    end
  end
end
