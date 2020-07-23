module Schemas
  module V1
    module Zone
      def self.schema
        Helpers.object_of(
          zone_schema.merge(
            parent: Helpers.object_of(zone_schema, extras: { nullable: true }),
            children: Helpers.array_of(zone_schema)
          ),
          extras: { required: %w[id name slug links tdwg_code tdwg_level species_count] }
        )
      end

      def self.zone_schema
        {
          id: { type: :integer },
          name: { type: :string },
          slug: { type: :string },
          tdwg_code: { type: :string },
          tdwg_level: { type: :integer },
          species_count: { type: :integer },
          links: Helpers.object_of({
            self: { type: :string },
            plants: { type: :string },
            species: { type: :string }
          }, extras: { required: %w[self plants species] })
        }
      end
    end
  end
end
