module Checks
  # Reports a trait column whose value is contradicted by a sourced fact
  # (trefle-api#328), when that disagreement needs a person.
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
  # The conflicts are Migrators::FactArbitration's, so the queue and the bulk
  # job agree on what a conflict is. Only what neither the ranking nor the
  # evidence can settle reaches a person:
  #
  #   - a scalar column the ranking lets a corroborated, stronger fact replace
  #     is FactArbitration's job, not a reviewer's;
  #   - a weaker source disagreeing with a stronger one that already won is not
  #     news;
  #   - a claim resting on fewer than MIN_OBSERVATIONS observations is not
  #     enough to overturn a value, and a reviewer can only reject it: on
  #     2026-10-20, 49 warnings of 1 or 2 observations were all rejected;
  #   - a set the column already contains (TRY's flowering months are often
  #     the onset alone: "may" against "may|jun|jul") does not contradict it.
  #     On the 2026-10-20 production data, that was 426 of 624 month conflicts.
  #
  # One warning per attribute. A warning holding several attributes is
  # accepted or rejected as a whole, so one weak claim sank the strong ones
  # beside it (23 observations of Rumex acetosa flowering, rejected with the
  # single observation of its light value). And a claim a reviewer rejected
  # is not filed again: the sweep revisits every species.
  class FactDivergence < Check

    MIN_OBSERVATIONS = 3

    # FactArbitration verdicts a person has to settle: a reviewed value that a
    # source contradicts, two sources of the same rank that disagree.
    HUMAN_VERDICTS = %i[community tie_at_top].freeze

    def run
      conflicts = reportable_conflicts
      close_outdated!(conflicts)
      conflicts.each {|conflict| report!(conflict) }
      conflicts.presence
    end

    # Check.run calls this when nothing diverges any more; #run has already
    # closed what no longer applies.
    def close_and_resolve!; end

    private

    def reportable_conflicts
      facts = @species.species_facts.active_status.where(attribute_name: attributes)
      Migrators::FactArbitration.conflicts_for(@species, facts, MIN_OBSERVATIONS).select {|c| reportable?(c) }
    end

    # Every trait column FactArbitration knows, sets included: it leaves the
    # sets out of its default run, which makes them a reviewer's call.
    def attributes
      Migrators::FactArbitration.arbitrable_attributes(Traits.completion_fields)
    end

    def reportable?(conflict)
      return false if contained_set?(conflict)
      return corroborated?(conflict) if HUMAN_VERDICTS.include?(conflict.verdict)

      conflict.verdict == :arbitrable && set_column?(conflict.attribute_name)
    end

    # The tie and community verdicts are given before FactArbitration looks at
    # the evidence, so the evidence is looked at here.
    def corroborated?(conflict)
      n = conflict.winner_n_observations
      (n.nil? || n >= MIN_OBSERVATIONS) && Traits.plausible?(conflict.attribute_name, conflict.winner_value)
    end

    def set_column?(attr)
      @species.public_send(attr).is_a?(ActiveFlag::Value)
    end

    def contained_set?(conflict)
      return false unless set_column?(conflict.attribute_name)

      claimed = flags_in(conflict.winner_value)
      claimed.any? && claimed.subset?(flags_in(conflict.column_value))
    end

    # TRY writes lists as "green, yellow", the column serializes "green|yellow".
    def flags_in(value)
      value.to_s.split(/[|,]/).map {|v| v.strip.downcase }.reject(&:empty?).to_set
    end

    def report!(conflict)
      attr = conflict.attribute_name
      correction = { attr => conflict.winner_value }
      previous = warnings.select {|rc| proposal(rc) == correction }
      return if previous.any? {|rc| rc.pending_change_status? || rc.rejected_change_status? }

      @existing_check = nil
      get_or_create_warning_for_record({ notes: notes_for(conflict) }, correction)
    end

    # A pending warning stays only while it is the one this run would file:
    # one attribute, still in conflict, with the same claim. The others (the
    # data was fixed, the source changed its claim, a warning from before one
    # warning per attribute) are closed as resolved.
    def close_outdated!(conflicts)
      current = conflicts.map {|c| { c.attribute_name => c.winner_value } }
      warnings.select(&:pending_change_status?).each do |rc|
        next if current.include?(proposal(rc))

        rc.update(notes: [rc.notes, "Closed by #{self.class}: no longer the claim to review"].join("\n"))
        rc.resolve!
      end
    end

    def warnings
      @warnings ||= RecordCorrection.where(record: @species, warning_type: self.class.to_s).to_a
    end

    def proposal(warning)
      JSON.parse(warning.correction_json.presence || '{}')
    rescue JSON::ParserError
      {}
    end

    def notes_for(conflict)
      n = conflict.winner_n_observations
      backed = conflict.backing_fact_id ? conflict.shown_source : 'no source (2022 value)'
      note = "#{conflict.attribute_name}: column is #{conflict.column_value.inspect} (#{backed}), " \
             "#{conflict.winner_source} claims #{conflict.winner_value.inspect}#{" (#{n} observations)" if n}"
      conflict.other_sources.present? ? "#{note}; also #{conflict.other_sources}" : note
    end

  end
end
