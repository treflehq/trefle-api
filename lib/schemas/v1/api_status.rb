module Schemas
  module V1
    module ApiStatus
      def self.dataset_schema
        Helpers.object_of(
          {
            version: Helpers::DATASET_VERSION,
            released_at: { type: :string, format: 'date-time', nullable: true, description: 'When the data operation that produced this version finished' },
            licence: { type: :string, description: 'SPDX identifier of the licence of the compiled data', example: 'CC-BY-4.0' },
            licence_url: { type: :string, format: :uri },
            citation_url: { type: :string, format: :uri, description: 'How to cite Trefle: formats, data version, access date and the upstream sources to co-cite' },
            changelog_url: { type: :string, format: :uri, description: 'The history of the data versions (`GET /api/v1/changelog`)' }
          },
          extras: {
            description: 'What to cite: the data version and where the citation and the version history live',
            required: %w[version released_at licence licence_url citation_url changelog_url]
          }
        )
      end

      def self.schema
        Helpers.object_of(
          {
            plants_count: { type: :integer, description: 'Total number of plants in the database' },
            detailed_plants_count: { type: :integer, description: 'Number of species carrying detailed trait data' },
            detailled_plants_count: {
              type: :integer,
              deprecated: true,
              description: 'Deprecated misspelling of `detailed_plants_count`, same value. Kept for existing clients; read `detailed_plants_count` instead.'
            },
            dataset_version: Helpers::DATASET_VERSION,
            dataset: dataset_schema
          },
          extras: { required: %w[plants_count detailed_plants_count detailled_plants_count dataset_version dataset] }
        )
      end
    end
  end
end
