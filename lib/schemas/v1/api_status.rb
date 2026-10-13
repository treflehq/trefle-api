module Schemas
  module V1
    module ApiStatus
      def self.schema
        Helpers.object_of(
          {
            plants_count: { type: :integer, description: 'Total number of plants in the database' },
            detailed_plants_count: { type: :integer, description: 'Number of species carrying detailed trait data' },
            detailled_plants_count: {
              type: :integer,
              deprecated: true,
              description: 'Deprecated misspelling of `detailed_plants_count`, same value. Kept for existing clients; read `detailed_plants_count` instead.'
            }
          },
          extras: { required: %w[plants_count detailed_plants_count detailled_plants_count] }
        )
      end
    end
  end
end
