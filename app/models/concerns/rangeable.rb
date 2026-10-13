module Rangeable
  extend ActiveSupport::Concern

  # Parses the public `range[field]=min,max` value into two optional numeric
  # bounds. Shared by the ActiveRecord path (#range_with) and the Searchkick
  # path (Api::ApiController#search_params) so both read a range the same way:
  #
  # - bounds are decimals (BigDecimal), not truncated integers: `6.5` stays 6.5;
  # - either side can be left empty: `,10` means "<= 10", `5,` means ">= 5";
  # - a negative bound is fine: `,-5` means "<= -5";
  # - on an integer column a decimal bound is rounded towards the inside of the
  #   range (`6.5,` -> >= 7, `,6.5` -> <= 6), which is what the decimal bound
  #   means on integer data, instead of ActiveRecord's silent truncation;
  # - anything that is not a number raises Filterable::InvalidFilterValueError
  #   (rendered as a 400) instead of being read as 0.
  #
  # Returns [min, max]; a bound is nil when left open.
  def self.parse_bounds(field, value, column_type: nil)
    raw_min, raw_max = value.to_s.split(',', 2)
    [
      parse_bound(field, raw_min, column_type, :min),
      parse_bound(field, raw_max, column_type, :max)
    ]
  end

  def self.parse_bound(field, raw, column_type, side)
    return nil if raw.blank?

    number = BigDecimal(raw.strip)
    raise ArgumentError, 'not finite' unless number.finite?
    return number unless column_type == :integer

    side == :min ? number.ceil : number.floor
  rescue ArgumentError
    raise Filterable::InvalidFilterValueError,
          "Invalid range value for #{field}: #{raw.strip.inspect} is not a number. " \
          "Use range[#{field}]=min,max with numeric bounds; leave a side empty for an open bound " \
          "(range[#{field}]=5, or range[#{field}]=,10)."
  end

  module ClassMethods
    def range_with(filtering_params)
      results = where(nil)
      filtering_params.each do |key, value|
        next if value.blank?

        min, max = Rangeable.parse_bounds(key, value, column_type: columns_hash[key.to_s]&.type)
        # `range[field]=,` carries no bound at all: nothing to constrain.
        next if min.nil? && max.nil?

        results = results.public_send("range_by_#{key}", min, max)
      end
      results
    end

    # Inclusive on both sides (BETWEEN); an open side becomes >= or <=.
    def where_in_range(field, min, max)
      return where(nil) if min.nil? && max.nil?

      where(field => (min..max))
    end
  end
end
