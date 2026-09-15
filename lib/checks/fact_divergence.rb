module Checks
  # Reports a trait column whose value is contradicted by a sourced fact
  # (trefle-api#328).
  #
  # Migrators::FactPromotion deliberately never overwrites a filled column: a
  # bulk job is the wrong place to settle a disagreement between two sources.
  # But silently dropping the disagreement is no better — the fact stays in the
  # provenance trail where nobody looks. This is where it surfaces: as a
  # warning in the corrections queue, for a human to accept or reject.
  #
  # Accepting goes through the base class, which ingests correction_json with
  # source 'community' — the strongest rank in traits.yml. That is the right
  # semantics: a person looked at the two claims and chose, so the outcome is a
  # human decision, not TRY's or POWO's.
  #
  # Only the strongest active fact per attribute is compared. A weaker source
  # disagreeing with a stronger one that already won is not news.
  class FactDivergence < Check

    def run
      divergences = diverging_attributes
      return if divergences.empty?

      notes = divergences.map do |attr, current, fact|
        "#{attr}: column is #{current.inspect}, #{fact.source} claims #{fact.value.inspect}" \
          "#{fact.n_observations ? " (#{fact.n_observations} observations)" : ''}"
      end

      get_or_create_warning_for_record(
        { notes: notes.join("\n") },
        divergences.to_h {|attr, _current, fact| [attr, fact.value] }
      )
    end

    private

    # [attribute, current column value, the fact that contradicts it]
    def diverging_attributes
      comparable_facts.filter_map do |attr, fact|
        # Traits.filled? needs the raw column (a flag's "empty" is the integer
        # 0); the comparison needs the accessor (read_attribute hands back the
        # bitmask integer, never an ActiveFlag::Value).
        next unless Traits.filled?(attr, @species.read_attribute(attr))

        current = @species.send(attr)
        next if same_value?(current, fact.value)

        [attr, comparable(current), fact]
      end
    end

    # Strongest active fact per contract attribute, excluding facts this
    # column's own value came from.
    def comparable_facts
      @species.species_facts
        .active_status
        .where(attribute_name: Traits.completion_fields & Species.column_names)
        .group_by(&:attribute_name)
        .transform_values {|facts| facts.min_by {|f| Traits.priority_index(f.source) } }
    end

    # The column holds a typed value, the fact holds the string the source
    # claimed. Compare in the fact's own terms rather than casting the string
    # back and hoping the round trip is lossless.
    #
    # A flag column serializes in bitmask order, not in the order the value was
    # written: `flower_color = %i[yellow white]` reads back as "white|yellow".
    # Comparing the joined strings would report a divergence for every colour
    # fact whose hues happen to be listed in a different order — and colours
    # are the bulk of what TRY contributes. Compare them as sets.
    def same_value?(current, claimed)
      return flag_set(current) == flag_set(claimed) if current.is_a?(ActiveFlag::Value)

      comparable(current).casecmp?(claimed.to_s)
    end

    def flag_set(value)
      raw = value.is_a?(ActiveFlag::Value) ? value.to_a : value.to_s.split('|')
      raw.map {|v| v.to_s.strip.downcase }.reject(&:empty?).to_set
    end

    def comparable(value)
      return value.to_a.join('|') if value.is_a?(ActiveFlag::Value)

      value.to_s
    end

  end
end
