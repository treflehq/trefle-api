module Checks
  # Flags numeric trait values outside their plausible_range (config/traits.yml)
  # and inconsistent min/max pairs. Accepting the warning drops the implausible
  # values (sets them to nil) and rejects the matching provenance facts.
  class PlausibleValues < Check

    def run
      problems = implausible_fields + out_of_vocabulary_fields
      cross = inconsistent_bounds

      return if problems.empty? && cross.empty?

      # Each problem carries its own reason: whoever triages this warning needs
      # to know which bound or which vocabulary was violated, not just that
      # something was.
      notes = problems.map {|name, value, reason| "#{name}=#{value.inspect} #{reason}" }
      notes += cross.map {|c| "inconsistent bounds: #{c}" }

      get_or_create_warning_for_record(
        notes: notes.join("\n"),
        correction_json: problems.to_h {|name, _value, _reason| [name, nil] }.to_json
      )
    end

    # Accepting means: these values are wrong, drop them.
    def accept!(user_id = nil)
      return unless @existing_check&.pending_change_status?

      fields = JSON.parse(@existing_check.correction_json || '{}').keys & Species.column_names
      @species.update!(fields.index_with { nil }) if fields.any?

      @species.species_facts.active_status.where(attribute_name: fields).find_each do |f|
        f.update!(status: :rejected, notes: [f.notes, 'rejected via Checks::PlausibleValues'].compact.join("\n"))
      end

      @existing_check.update(accepted_by: user_id, change_status: :accepted)
    end

    private

    def implausible_fields
      Traits.fields.keys.filter_map do |name|
        value = @species.attributes[name]
        next unless value.is_a?(Numeric)
        next if Traits.plausible?(name, value)

        [name, value, "outside the plausible range #{Traits.field(name)['plausible_range'].inspect}"]
      end
    end

    # Free-text columns constrained by a closed vocabulary (allowed_values)
    def out_of_vocabulary_fields
      Traits.fields.keys.filter_map do |name|
        next unless Traits.allowed_values(name)

        value = @species.attributes[name]
        next if value.nil? || Traits.allowed_value?(name, value)

        [name, value, "outside the allowed vocabulary #{Traits.allowed_values(name).inspect}"]
      end
    end

    def inconsistent_bounds
      Traits.cross_field_rules.filter_map do |rule|
        min = @species.attributes[rule['min']]
        max = @species.attributes[rule['max']]
        next unless min.is_a?(Numeric) && max.is_a?(Numeric) && min > max

        "#{rule['min']}=#{min} > #{rule['max']}=#{max}"
      end
    end

  end
end
