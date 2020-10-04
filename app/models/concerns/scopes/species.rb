module Scopes
  module Species
    extend ActiveSupport::Concern

    included do # rubocop:todo Metrics/BlockLength
      
      Api::V1::SpeciesController::FILTERABLE_FIELDS.each do |field|
        # scope "filter_by_#{field}".to_sym, ->(v) { where(field => v) }
        scope "filter_by_#{field}".to_sym, lambda {|v|
          ::Species::COLUMN_TYPES[field] == :string ? where("lower(#{field}) IN (?)", [*v].map(&:to_s).map(&:downcase)) : where(field => v)
        }
      end

      Api::V1::SpeciesController::FILTERABLE_NOT_FIELDS.each do |field|
        scope "filter_not_by_#{field}".to_sym, lambda {|value|
          puts "filter_not_by_#{field} -> #{value.inspect}"
          coll = ::Species::COLUMN_TYPES[field] == :string ? where.not("lower(#{field}) IN (?)", [*value].map(&:to_s).map(&:downcase)) : where.not(field => value)
          coll = coll.or(where(field => nil)) unless [*value].include?(nil)
          coll
        }
      end

      ::Species.active_flags.each_key do |flag|
        scope "filter_not_by_#{flag}".to_sym, lambda {|value|
          puts "filter_not_by_#{flag} -> #{value.inspect}"
          flagger = ::Species.active_flags[flag]
          if value && value.first
            values = flagger.maps.keys - [*value].map(&:to_sym)

            if values == flagger.maps.keys
              where.not(flag => [0, nil])
            else
              int_val = flagger.to_i(values)
              where.not("species.#{flag} & #{int_val} > 0")
            end
          else
            where.not(flag => [0, nil])
          end
        }
      end

      # Associations overrides
      scope :filter_by_establishment, ->(v) { joins(:species_distributions).where(species_distributions: { establishment: v }).distinct }

      # Binary flags overrides
      scope :filter_by_duration, ->(v) { where_duration(*v) }
      scope :filter_not_by_duration, ->(_v) { where.not(duration: [0, nil]) }
      scope :filter_by_growth_months, ->(v) { where_growth_months(*v) }
      scope :filter_not_by_growth_months, ->(_v) { where.not(growth_months: [0, nil]) }
      scope :filter_by_bloom_months, ->(v) { where_bloom_months(*v) }
      scope :filter_not_by_bloom_months, ->(_v) { where.not(bloom_months: [0, nil]) }
      scope :filter_by_fruit_months, ->(v) { where_fruit_months(*v) }
      scope :filter_not_by_fruit_months, ->(_v) { where.not(fruit_months: [0, nil]) }
      scope :filter_by_flower_color, ->(v) { where_flower_color(*v) }
      scope :filter_not_by_flower_color, ->(_v) { where.not(flower_color: [0, nil]) }
      scope :filter_by_foliage_color, ->(v) { where_foliage_color(*v) }
      scope :filter_not_by_foliage_color, ->(_v) { where.not(foliage_color: [0, nil]) }
      scope :filter_by_fruit_color, ->(v) { where_fruit_color(*v) }
      scope :filter_not_by_fruit_color, ->(_v) { where.not(fruit_color: [0, nil]) }
      scope :filter_by_edible_part, ->(v) { where_edible_part(*v) }
      # scope :filter_not_by_edible_part, lambda {|value|
      #   puts "VALUE = #{value.inspect}"
      #   if value
      #     values = ::Species.edible_parts.maps.keys - [*value].map(&:to_sym)

      #     if values == ::Species.edible_parts.maps.keys
      #       where.not(edible_part: [0, nil])
      #     else
      #       int_val = ::Species.edible_parts.to_i(values)
      #       where.not("species.edible_part & #{int_val} > 0")
      #     end
      #   else
      #     where.not(edible_part: [0, nil])
      #   end
      # }
      scope :filter_not_by_image_url, ->(_v) { where.not(main_image_url: nil) }

      # Ranges
      scope :range_by_year, ->(a, b) { where(year: ((a&.to_i || -3000)...(b&.to_i || 3000))) }
      scope :range_by_atmospheric_humidity, ->(a, b) { where(atmospheric_humidity: ((a&.to_i || 0)...(b&.to_i || 3000))) }
      # scope :range_by_bloom_months, ->(a, b) { where(bloom_months: ((a&.to_i || 0)...(b&.to_i || 3000))) }
      # scope :range_by_duration, ->(a, b) { where(duration: ((a&.to_i || 0)...(b&.to_i || 3000))) }
      scope :range_by_frost_free_days_minimum, ->(a, b) { where(frost_free_days_minimum: ((a&.to_i || 0)...(b&.to_i || 3000))) }
      # scope :range_by_fruit_months, ->(a, b) { where(fruit_months: ((a&.to_i || 0)...(b&.to_i || 3000))) }
      scope :range_by_ground_humidity, ->(a, b) { where(ground_humidity: ((a&.to_i || 0)...(b&.to_i || 3000))) }
      # scope :range_by_growth_months, ->(a, b) { where(growth_months: ((a&.to_i || 0)...(b&.to_i || 3000))) }
      scope :range_by_images_count, ->(a, b) { where(images_count: ((a&.to_i || 0)...(b&.to_i || 3000))) }
      scope :range_by_light, ->(a, b) { where(light: ((a&.to_i || 0)...(b&.to_i || 3000))) }
      scope :range_by_average_height_cm, ->(a, b) { where(average_height_cm: ((a&.to_i || 0)...(b&.to_i || 3_000_000))) }
      scope :range_by_maximum_height_cm, ->(a, b) { where(maximum_height_cm: ((a&.to_i || 0)...(b&.to_i || 3_000_000))) }
      scope :range_by_maximum_precipitation_mm, ->(a, b) { where(maximum_precipitation_mm: ((a&.to_i || 0)...(b&.to_i || 3_000_000))) }
      scope :range_by_maximum_temperature_deg_c, ->(a, b) { where(maximum_temperature_deg_c: ((a&.to_i || 0)...(b&.to_i || 3000))) }
      scope :range_by_maximum_temperature_deg_f, ->(a, b) { where(maximum_temperature_deg_f: ((a&.to_i || 0)...(b&.to_i || 3000))) }
      # scope :range_by_minimum_planting_density, ->(a, b) { where(minimum_planting_density: ((a&.to_i || 0)...(b&.to_i || 3000))) }
      scope :range_by_minimum_precipitation_mm, ->(a, b) { where(minimum_precipitation_mm: ((a&.to_i || 0)...(b&.to_i || 3_000_000))) }
      scope :range_by_minimum_root_depth_cm, ->(a, b) { where(minimum_root_depth_cm: ((a&.to_i || 0)...(b&.to_i || 3_000_000))) }
      scope :range_by_minimum_temperature_deg_c, ->(a, b) { where(minimum_temperature_deg_c: ((a&.to_i || 0)...(b&.to_i || 3000))) }
      scope :range_by_minimum_temperature_deg_f, ->(a, b) { where(minimum_temperature_deg_f: ((a&.to_i || 0)...(b&.to_i || 3000))) }
      scope :range_by_ph_maximum, ->(a, b) { where(ph_maximum: ((a&.to_i || 0)...(b&.to_i || 3000))) }
      scope :range_by_ph_minimum, ->(a, b) { where(ph_minimum: ((a&.to_i || 0)...(b&.to_i || 3000))) }
      scope :range_by_planting_days_to_harvest, ->(a, b) { where(planting_days_to_harvest: ((a&.to_i || 0)...(b&.to_i || 3000))) }
      scope :range_by_planting_row_spacing_cm, ->(a, b) { where(planting_row_spacing_cm: ((a&.to_i || 0)...(b&.to_i || 3_000_000))) }
      scope :range_by_planting_spread_cm, ->(a, b) { where(planting_spread_cm: ((a&.to_i || 0)...(b&.to_i || 3_000_000))) }
      scope :range_by_soil_nutriments, ->(a, b) { where(soil_nutriments: ((a&.to_i || 0)...(b&.to_i || 3000))) }
      scope :range_by_soil_salinity, ->(a, b) { where(soil_salinity: ((a&.to_i || 0)...(b&.to_i || 3000))) }
      scope :range_by_soil_texture, ->(a, b) { where(soil_texture: ((a&.to_i || 0)...(b&.to_i || 3000))) }
      scope :range_by_synonyms_count, ->(a, b) { where(synonyms_count: ((a&.to_i || 0)...(b&.to_i || 3000))) }
      scope :range_by_sources_count, ->(a, b) { where(sources_count: ((a&.to_i || 0)...(b&.to_i || 3000))) }
      scope :range_by_toxicity, ->(a, b) { where(toxicity: ((a&.to_i || 0)...(b&.to_i || 3000))) }
      scope :range_by_year, ->(a, b) { where(year: ((a&.to_i || 0)...(b&.to_i || 3000))) }

      # Search
      scope :database_search, lambda {|q|
        where('full_token ILIKE ?', "%#{q}%")
      }

      # plants
      scope :plants, -> { where(main_species_id: nil) }
      scope :vegetable, ->(_v) { where(vegetable: true) }
      scope :edible, ->(_v) { where.not(edible_part: [0, nil]) }

    end
  end
end
