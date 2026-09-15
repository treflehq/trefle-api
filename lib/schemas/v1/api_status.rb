module Schemas
  module V1
    module ApiStatus
      def self.schema
        Helpers.object_of(
          {
            plants_count: { type: :integer, description: 'Total number of plants in the database' },
            detailled_plants_count: { type: :integer, description: 'Number of plants carrying detailed trait data' }
          },
          extras: { required: %w[plants_count detailled_plants_count] }
        )
      end
    end
  end
end
