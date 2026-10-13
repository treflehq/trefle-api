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
      return convert_vocabulary_value(key, stripped) if filter_vocabulary(key)

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

    # The closed set of values a filter key accepts, or nil when the field is
    # open (names, authors, numbers...). A Hash is an enum mapping (name =>
    # stored integer), an Array a plain list of names. Models opt in by
    # overriding #filter_vocabularies; see Scopes::Species.
    def filter_vocabulary(key)
      filter_vocabularies[key.to_s]
    end

    def filter_vocabularies
      {}
    end

    # For the Searchkick path (Api::ApiController#search_params), which sends
    # the other values to the index as given: a value of a closed vocabulary
    # is checked and put in its canonical spelling, as convert_value does on
    # the ActiveRecord path, so an unknown one answers 400 there too.
    def canonical_filter_value(key, value)
      filter_vocabulary(key) ? convert_value(key, value) : value
    end

    # Names of the accepted values, for messages and documentation.
    def filter_vocabulary_names(key)
      vocabulary = filter_vocabulary(key)
      vocabulary.is_a?(Hash) ? vocabulary.keys : vocabulary
    end

    private

    # An enum or flag value outside its vocabulary used to reach the query as
    # is: ActiveRecord casts an unknown enum name to NULL (`filter[status]=foobar`
    # returned the species without a status) and active_flag to 0 (no rows),
    # so a typo answered 200 with the wrong records. Match the name
    # case-insensitively (`Accepted` used to be cast to NULL too) and return
    # it in its canonical spelling; an enum also keeps accepting the stored
    # integer (`filter[status]=0`), which ActiveRecord always took.
    def convert_vocabulary_value(key, value)
      return nil if value.casecmp?('null')

      vocabulary = filter_vocabulary(key)
      names = filter_vocabulary_names(key)
      match = names.find {|name| name.to_s.casecmp?(value) }
      match ||= vocabulary.key(Integer(value, 10, exception: false)) if vocabulary.is_a?(Hash)
      return match.to_s if match

      raise InvalidFilterValueError, "Invalid value for #{key}: #{value.inspect}. " \
        "Accepted values are: #{names.join(', ')}."
    end

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
