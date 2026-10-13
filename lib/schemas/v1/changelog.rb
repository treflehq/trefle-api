module Schemas
  module V1
    # GET /api/v1/changelog (Api::V1::ChangelogController): the public history
    # of the data versions.
    module Changelog
      def self.entry_schema
        Helpers.object_of(
          {
            version: { type: :string, description: 'The data version this operation produced', example: '2026.10.13' },
            kind: { type: :string, description: 'What the operation was (import, migration, purge...)', example: 'import' },
            status: { type: :string, enum: %w[completed failed], description: 'A failed operation may still have written part of its changes, so it produces a version too' },
            started_at: { type: :string, format: 'date-time' },
            finished_at: { type: :string, format: 'date-time' },
            changes: {
              type: :object,
              additionalProperties: { type: :integer },
              description: 'Observed change in the row counts the operation moved (species, synonyms, species_facts, ' \
                           'active_facts, common_names, species_distributions...), measured before and after it ran. ' \
                           'Rows updated in place do not show here.',
              example: { species_facts: 267_412, active_facts: 84_310 }
            }
          },
          extras: { required: %w[version kind status started_at finished_at changes] }
        )
      end

      def self.schema
        Helpers.object_of(
          {
            data: { type: :array, items: entry_schema },
            meta: Helpers.object_of(
              {
                total: { type: :integer, description: 'Number of entries returned (the latest 100 at most)' },
                dataset_version: Helpers::DATASET_VERSION
              },
              extras: { required: %w[total dataset_version] }
            )
          },
          extras: { required: %w[data meta] }
        )
      end
    end
  end
end
