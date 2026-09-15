module Schemas
  module V1
    module SpeciesFact
      def self.schema
        Helpers.object_of(
          {
            attribute_name: { type: :string, description: 'The species attribute this claim is about (ex: `average_height_cm`)' },
            source: { type: :string, description: 'The source making the claim (ex: `powo`, `try`, `gbif`)' },
            value: { type: :string, nullable: true, description: 'The claimed value, as a string' },
            unit: { type: :string, nullable: true, description: 'The unit of the value, when the attribute carries one' },
            evidence_type: {
              type: :string, enum: ::SpeciesFact.evidence_types.keys,
              description: 'How the claim is backed. `reported`: asserted by an external database. `measured`: backed by referenced measurements. ' \
                           '`derived`: computed by us from primary data. `inferred`: imputed, ex: from congeneric species.'
            },
            status: {
              type: :string, enum: ::SpeciesFact.statuses.keys,
              description: '`active`: the current claim from this source. `superseded`: replaced by a newer claim from the same source. ' \
                           '`rejected`: failed plausibility validation and was never applied.'
            },
            notes: { type: :string, nullable: true },
            source_record_id: { type: :string, nullable: true, description: 'The identifier of the record at the source' },
            source_url: { type: :string, nullable: true, description: 'A link to the record at the source' },
            n_observations: { type: :integer, nullable: true, description: 'Number of underlying observations, for measured facts' },
            observed_at: { type: :string, nullable: true },
            updated_at: { type: :string, nullable: true }
          },
          extras: { required: %w[attribute_name source evidence_type status] }
        )
      end
    end
  end
end
