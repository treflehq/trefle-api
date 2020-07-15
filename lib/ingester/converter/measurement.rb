require 'httparty'
require 'colorize'

# Will convert measurement like fields
module Ingester
  module Converter
    class Measurement

      class MeasurementException < IngesterException

      end

      DEFAULT_MEASUREMENTS = {
        average_height: 'cm',
        maximum_height: 'cm',
        maximum_precipitation: 'mm',
        # minimum_planting_density: 'm2',
        minimum_precipitation: 'mm',
        minimum_root_depth: 'cm',
        planting_row_spacing: 'cm',
        planting_spread: 'cm'
      }.freeze

      FIELDS = %w[
        average_height
        maximum_height
        maximum_precipitation
        minimum_precipitation
        minimum_root_depth
      ].freeze

      # Will convert measurement like fields
      def self.resolve!(hash)
        data = FIELDS.each_with_object({}) do |metric, memo|
          value, unit = hash.slice(
            "#{metric}_value".to_sym,
            "#{metric}_unit".to_sym
          ).values

          next(memo) unless value && unit

          # raise MeasurementException, "Mission value (#{value}) or unit #{unit} for field #{metric}" if (value && unit)

          good_unit = DEFAULT_MEASUREMENTS[metric.to_sym]
          puts "Value = #{value.inspect}"
          puts "Unit = #{unit.inspect}"
          raise MeasurementException, "Invalid value (#{value}) or unit #{unit} for field #{metric}" if value.blank? || value.to_s.gsub(',', '.').to_f == 0.0

          new_value = Measured::Length.new(value.to_s.gsub(',', '.').to_f.to_s, unit).convert_to(good_unit).value.to_i
          puts "[Converter][Measurement] Species.#{metric}_value = #{new_value}"
          puts "[Converter][Measurement] Species.#{metric}_unit = #{good_unit}"

          memo["#{metric}_#{good_unit}"] = new_value
        end
        data&.deep_symbolize_keys
      end
    end
  end
end
