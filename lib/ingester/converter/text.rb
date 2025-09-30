require 'httparty'
require 'colorize'

# Will convert text fields
module Ingester
  module Converter
    class Text

      class TextException < IngesterException

      end

      FIELDS = %I[
        anaerobic_tolerance
        c_n_ratio
        caco_3_tolerance
        family_common_name
        growth_form
        growth_habit
        growth_rate
        lifespan
        maturation_order
        nitrogen_fixation
        protein_potential
        shape_and_orientation

        bibliography
        observations
        planting_description
        planting_sowing_description

        biological_type_raw
        dissemination_raw
        fruit_shape_raw
        inflorescence_raw
        maturation_order_raw
        pollinisation_raw
        sexuality_raw
      ].freeze

      # Will convert measurement like fields
      def self.resolve!(hash)
        data = FIELDS.each_with_object({}) do |metric, memo|
          next(memo) if hash[metric].nil?

          puts "[Converter][Text] Species.#{metric} = #{hash[metric]}"

          memo[metric] = hash[metric]&.strip
        end
        data&.deep_symbolize_keys
      end

    end
  end
end
