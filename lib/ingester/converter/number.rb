require 'httparty'
require 'colorize'

# Will convert text fields
module Ingester
  module Converter
    class Number

      class NumberException < IngesterException

      end

      FIELDS = %I[
        atmospheric_humidity
        biological_type
        dissemination
        fruit_shape
        ground_humidity
        hardiness_zone
        images_count
        inflorescence_form
        inflorescence_type
        light
        planting_days_to_harvest
        planting_row_spacing_cm
        planting_spread_cm
        pollinisation
        sexuality
        soil_nutriments
        soil_salinity
        year
        frost_free_days_minimum
      ].freeze

      # Will convert measurement like fields
      def self.resolve!(hash)
        data = FIELDS.each_with_object({}) do |metric, memo|
          next(memo) if hash[metric].nil?

          memo[metric] = hash[metric]
          puts "[Converter][Number] Species.#{metric} = #{memo[metric]}"

          memo[metric] = memo[metric]&.strip.to_i if memo[metric].is_a?(String)
        end
        data&.deep_symbolize_keys
      end

    end
  end
end
