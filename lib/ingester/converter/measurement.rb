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

      # Will convert measurement like fields.
      #
      # Accepts either an explicit `<metric>_value` + `<metric>_unit` pair (any
      # length unit, converted to the canonical one), or the canonical column
      # itself (`average_height_cm`, `minimum_precipitation_mm`...) which is
      # what the import pipelines already produce. The explicit pair wins when
      # both are given, since it carries its own unit.
      def self.resolve!(hash)
        data = FIELDS.each_with_object({}) do |metric, memo|
          good_unit = DEFAULT_MEASUREMENTS[metric.to_sym]
          value, unit = hash.slice("#{metric}_value".to_sym, "#{metric}_unit".to_sym).values

          converted = if value.nil? && unit.nil?
                        canonical_value(hash, metric, good_unit)
                      else
                        converted_value(value, unit, metric, good_unit)
                      end

          memo["#{metric}_#{good_unit}"] = converted unless converted.nil?
        end
        data&.deep_symbolize_keys
      end

      # The canonical column (average_height_cm, minimum_precipitation_mm...) is
      # already in the right unit, so it is taken as-is: no conversion, and 0
      # stays a legitimate value (a rootless aquatic plant really does have
      # minimum_root_depth_cm = 0).
      def self.canonical_value(hash, metric, good_unit)
        given = hash["#{metric}_#{good_unit}".to_sym]
        return nil if given.nil? || given.to_s.strip.empty?

        given.to_s.gsub(',', '.').to_f.to_i
      end

      def self.converted_value(value, unit, metric, good_unit)
        return nil unless value && unit

        puts "Value = #{value.inspect}"
        puts "Unit = #{unit.inspect}"
        raise MeasurementException, "Invalid value (#{value}) or unit #{unit} for field #{metric}" if value.blank? || value.to_s.gsub(',', '.').to_f == 0.0

        new_value = Measured::Length.new(value.to_s.gsub(',', '.').to_f.to_s, unit).convert_to(good_unit).value.to_i
        puts "[Converter][Measurement] Species.#{metric}_value = #{new_value}"
        puts "[Converter][Measurement] Species.#{metric}_unit = #{good_unit}"

        new_value
      end
    end
  end
end
