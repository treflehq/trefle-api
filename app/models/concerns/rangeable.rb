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
  #   (rendered as a 400) instead of being read as 0;
  # - a lower bound greater than the upper bound (`range[ph_minimum]=7,5`)
  #   raises too: it can match nothing, and was answered with an empty page
  #   that read like "no species". It is compared on the bounds as given, before
  #   the integer rounding below (`6.2,6.8` is a valid range with no integer in
  #   it, not an inverted one).
  #
  # Returns [min, max]; a bound is nil when left open.
  def self.parse_bounds(field, value, column_type: nil)
    raw_min, raw_max = value.to_s.split(',', 2)
    min = parse_bound(field, raw_min)
    max = parse_bound(field, raw_max)
    ensure_ordered!(field, raw_min, raw_max, min, max)
    [
      round_bound(min, column_type, :min),
      round_bound(max, column_type, :max)
    ]
  end

  def self.parse_bound(field, raw)
    return nil if raw.blank?

    number = BigDecimal(raw.strip)
    raise ArgumentError, 'not finite' unless number.finite?

    number
  rescue ArgumentError
    raise Filterable::InvalidFilterValueError,
          "Invalid range value for #{field}: #{raw.strip.inspect} is not a number. " \
          "Use range[#{field}]=min,max with numeric bounds; leave a side empty for an open bound " \
          "(range[#{field}]=5, or range[#{field}]=,10)."
  end

  def self.ensure_ordered!(field, raw_min, raw_max, min, max)
    return if min.nil? || max.nil? || min <= max

    raise Filterable::InvalidFilterValueError,
          "Invalid range for #{field}: the lower bound #{raw_min.strip} is greater than the upper bound #{raw_max.strip}. " \
          "Use range[#{field}]=min,max with min <= max (range[#{field}]=#{raw_max.strip},#{raw_min.strip})."
  end

  def self.round_bound(number, column_type, side)
    return number if number.nil? || column_type != :integer

    side == :min ? number.ceil : number.floor
  end

  # The hint added to the 400 of an unknown filter key that is a rangeable
  # numeric field (`filter[light]=9`): such a field is filtered with
  # `range[light]`, which the bare "unknown key" message did not say.
  # provided: the filter params, to echo the client's value in the example.
  def self.range_hint(unknown_keys, range_fields, provided)
    numeric = unknown_keys & range_fields.map(&:to_s)
    return '' if numeric.empty?

    field = numeric.first
    value = provided[field].to_s.split(',').first.presence || 'min'
    "#{numeric.join(', ')} #{numeric.size > 1 ? 'are numeric fields' : 'is a numeric field'}: " \
      "use range[#{field}]=min,max instead (range[#{field}]=#{value},#{value} for an exact value). "
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
