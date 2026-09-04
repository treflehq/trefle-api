module Checks
  # Flags numeric trait values outside their plausible_range (config/traits.yml)
  # and inconsistent min/max pairs. Accepting the warning drops the implausible
  # values (sets them to nil) and rejects the matching provenance facts.
  class PlausibleValues < Check

    def run
      implausible = implausible_fields
      cross = inconsistent_bounds

      return if implausible.empty? && cross.empty?

      notes = implausible.map {|n, v| "#{n}=#{v} outside plausible range #{Traits.field(n)['plausible_range']}" }
      notes += cross.map {|c| "inconsistent bounds: #{c}" }

      get_or_create_warning_for_record(
        notes: notes.join("\n"),
        correction_json: implausible.to_h {|n, _v| [n, nil] }.to_json
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

        [name, value]
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
