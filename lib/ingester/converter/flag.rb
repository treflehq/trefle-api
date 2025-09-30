require 'httparty'
require 'colorize'

# Will convert measurement like fields
module Ingester
  module Converter
    class Flag

      class FlagException < IngesterException

      end

      FIELDS = %I[
        duration
        growth_months
        bloom_months
        fruit_months
        flower_color
        fruit_color
        foliage_color
        edible_part
      ].freeze

      # Will convert falgs like fields
      def self.resolve!(hash)
        data = FIELDS.each_with_object({}) do |metric, memo|
          next(memo) if hash[metric].nil?

          keys = filter_keys(hash[metric])

          puts "[Converter][Flag] Species.#{metric} = #{keys.inspect} (metric was #{hash[metric].inspect})"
          check_keys!(metric, keys)

          memo[metric] = keys
        end
        data&.deep_symbolize_keys
      end

      def self.filter_keys(hash_metric)

        if hash_metric.is_a?(String) && hash_metric&.split('|').length == 1
          hash_metric = hash_metric&.split(',')
        end
        
        array_flags = hash_metric.is_a?(Array) ? hash_metric : hash_metric&.split('|')

        array_flags&.map {|e| e&.to_s&.strip&.to_sym }&.reject(&:blank?)&.compact
      end

      def self.check_keys!(metric, keys)
        accepted_keys = ::Species.send(metric.to_s.pluralize)&.send(:keys)
        invalid = keys - accepted_keys

        return true unless invalid.any?

        raise FlagException, "Invalid #{metric} value: #{invalid.join(', ')}. Available #{metric} are: '#{accepted_keys.join(', ')}'"
      end

    end
  end
end
