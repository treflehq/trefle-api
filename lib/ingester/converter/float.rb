require 'httparty'
require 'colorize'

# Will convert text fields
module Ingester
  module Converter
    class Float

      class FloatException < IngesterException

      end

      # TODO: minimum_planting_density_value
      FIELDS = %I[
        maximum_temperature_deg_c
        maximum_temperature_deg_f
        minimum_temperature_deg_c
        minimum_temperature_deg_f
        ph_maximum
        ph_minimum
      ].freeze

      # Will convert float like fields
      def self.resolve!(hash)
        data = FIELDS.each_with_object({}) do |metric, memo|
          value = hash[metric]
          next(memo) if value.nil?

          value = Float(value&.strip) if value.is_a?(String)
          puts "[Converter][Float] Species.#{metric} = #{value.to_f.floor(2)}"

          memo[metric] = value.to_f.floor(2)
        end
        data&.deep_symbolize_keys
      end

    end
  end
end
