module Scopes
  module Plants
    extend ActiveSupport::Concern

    included do
      # Filters
      scope :filter_by_family_id, ->(family_id) { where(family_id: family_id) }
      scope :filter_by_author, ->(v) { where('LOWER(author) IN (?)', v) }
      scope :filter_by_common_name, ->(v) { where('LOWER(common_name) IN (?)', v) }
      scope :filter_by_complete, ->(v) { where(complete_data: v.join('') == 'true') }
      scope :filter_by_family_common_name, ->(v) { where('LOWER(family_common_name) IN (?)', v) }
      scope :filter_by_scientific_name, ->(v) { where('LOWER(scientific_name) IN (?)', v) }
      scope :filter_by_vegetable, ->(v) { where(vegetable: v) }
      # scope :filter_by_vegetable_category, ->(v) { where(vegetable_category: v) }
      scope :filter_by_year, ->(v) { where(year: v) }

      # Ranges
      scope :range_by_year, ->(a, b) { where(year: ((a&.to_i || -3000)...(b&.to_i || 3000))) }
      scope :range_by_species_count, ->(a, b) { where(species_count: ((a&.to_i || 0)...(b&.to_i || 3000))) }
      scope :range_by_images_count, ->(a, b) { where(images_count: ((a&.to_i || 0)...(b&.to_i || 3000))) }

      # Search
      scope :database_search, lambda {|q|
        joins(:species).where('species.full_token ILIKE ?', "%#{q}%")
      }
    end
  end
end
