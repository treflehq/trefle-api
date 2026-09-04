# Reads config/traits.yml — the per-field data contract used for the
# completion ratio, ingester source arbitration and data quality checks.
module Traits
  class << self

    def config
      @config ||= YAML.load_file(Rails.root.join('config/traits.yml'))
    end

    # Used by tests to force a reload
    def reset!
      @config = nil
      @completion_fields = nil
      @source_priority = nil
      @legacy_value_priority_index = nil
    end

    def fields
      config['fields']
    end

    def field(name)
      fields[name.to_s]
    end

    def counted_categories
      config.dig('completion', 'counted_categories')
    end

    # Field names participating in the completion ratio
    def completion_fields
      @completion_fields ||= fields.select {|_, spec| counted_categories.include?(spec['category']) }.keys
    end

    # A field only counts as "missing" when it makes sense for this species
    # (e.g. planting_* fields for edible/vegetable species only)
    def applicable?(name, species)
      case field(name)&.fetch('applicable_if', 'always')
      when 'edible_or_vegetable'
        species.vegetable || species.edible || species.edible_part&.any? ? true : false
      else
        true
      end
    end

    # Is this raw attribute value considered filled?
    # - false is information (e.g. leaf_retention: false)
    # - 0 is information, except for bitmask/enum fields where 0 = undocumented
    def filled?(name, value)
      return true if value == false
      return false if value.nil?
      return false if value.is_a?(String) && value.strip.empty?
      return false if field(name)&.dig('zero_means_empty') && value.respond_to?(:zero?) && value.zero?

      true
    end

    # Numeric plausibility according to plausible_range. Non-numeric values and
    # fields without a range are always considered plausible here.
    def plausible?(name, value)
      range = field(name)&.dig('plausible_range')
      return true unless range && value.is_a?(Numeric)

      value >= range[0] && value <= range[1]
    end

    def cross_field_rules
      config['cross_field_rules'] || []
    end

    # --- Source arbitration -------------------------------------------------

    def source_priority
      @source_priority ||= config.dig('sources', 'default_priority').map(&:downcase)
    end

    # Lower index = stronger source. Unknown sources rank last.
    def priority_index(source)
      return source_priority.length if source.nil?

      source_priority.index(source.to_s.downcase) || source_priority.length
    end

    def stronger_or_equal?(source, other)
      priority_index(source) <= priority_index(other)
    end

    # Rank given to a filled column that carries no fact (written before
    # provenance recording existed). See sources.legacy_value_rank.
    def legacy_value_priority_index
      @legacy_value_priority_index ||= priority_index(config.dig('sources', 'legacy_value_rank'))
    end

  end
end
