require 'httparty'
require 'colorize'

# Will convert text fields
module Ingester
  module Converter
    class Enum

      class EnumException < IngesterException

      end

      FIELDS = %I[
        rank
        status
        toxicity
        foliage_texture
        ligneous_type
        soil_texture
      ].freeze

      # Will convert measurement like fields
      def self.resolve!(hash)
        data = FIELDS.each_with_object({}) do |metric, memo|
          next(memo) if hash[metric].nil?

          value = hash[metric]
          value = resolve_number(metric, value) if value.match(/^[\d]+$/)
          puts "[Converter][Enum] Species.#{metric} = #{value.inspect}"

          memo[metric] = value&.to_sym
        end
        data&.deep_symbolize_keys
      end

      def self.resolve_number(field, value)
        sym_value = ::Species.send(field.to_s.pluralize).find {|_k, v| v == value&.to_i }
        raise EnumException, "Wrong value: #{value}, available values are: #{::Species.send(field.to_s.pluralize)}" unless sym_value.any?

        sym_value[0]
      end

    end
  end
end
