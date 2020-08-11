require 'httparty'
require 'colorize'

# Will convert text fields
module Ingester
  module Converter
    class Boolean

      class BooleanException < IngesterException

      end

      FIELDS = %I[
        edible
        flower_conspicuous
        fruit_conspicuous
        fruit_seed_persistence
        known_allelopath
        leaf_retention
        vegetable
      ].freeze

      # Will convert measurement like fields
      def self.resolve!(hash)
        data = FIELDS.each_with_object({}) do |metric, memo|
          next(memo) if hash[metric].nil?

          if hash[metric].is_a?(String)
            hash[metric] = true if hash[metric].underscore == 'true'
            hash[metric] = false if hash[metric].underscore == 'false'
          end
          memo[metric] = hash[metric]
          puts "[Converter][Boolean] Species.#{metric} = #{memo[metric]}"
        end
        data&.deep_symbolize_keys
      end

    end
  end
end
