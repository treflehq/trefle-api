module Filterable
  extend ActiveSupport::Concern

  # Raised (rendered as 400, same style as ApiController::UnknownQueryKeyError)
  # when a boolean-column filter is given a token outside the accepted set.
  class InvalidFilterValueError < StandardError; end

  TRUE_VALUES = %w[true yes 1 on].freeze
  FALSE_VALUES = %w[false no 0 off].freeze

  module ClassMethods
    def filter_with(filtering_params)
      results = where(nil)
      filtering_params.each do |key, value|
        results = results.public_send("filter_by_#{key}", value.split(',').map {|e| convert_value(key, e) }.compact) if value.present?
      end
      results
    end

    def filter_not_with(filtering_params)
      results = where(nil)
      filtering_params.each do |key, value|
        vs = value.present? ? value.split(',').map {|e| convert_value(key, e) } : nil
        results = results.public_send("filter_not_by_#{key}", vs)
      end
      results
    end

    def convert_value(key, value)
      stripped = value.strip
      return convert_boolean_value(key, stripped) if boolean_column?(key)

      case stripped
      when 'true'
        true
      when 'false'
        false
      when 'null'
        nil
      else
        stripped
      end
    end

    private

    def boolean_column?(key)
      columns_hash[key.to_s]&.type == :boolean
    end

    # ActiveModel's own boolean cast doesn't list "no" among its FALSE_VALUES,
    # so `where(edible: "no")` used to silently cast to true and collide with
    # `filter[edible]=yes` (#277/#56). Accept a fixed, documented token set
    # instead of leaning on that cast.
    def convert_boolean_value(key, value)
      normalized = value.downcase
      return true if TRUE_VALUES.include?(normalized)
      return false if FALSE_VALUES.include?(normalized)
      return nil if normalized == 'null'

      raise InvalidFilterValueError, "Invalid value for #{key}: #{value}. " \
        "Accepted values are: #{(TRUE_VALUES + FALSE_VALUES).join(', ')}."
    end
  end
end
