module Schemas
  module V1
    module Zone
      def self.schema
        Helpers.object_of(
          zone_schema.merge(
            parent: Helpers.object_of(zone_schema, extras: { nullable: true }),
            children: Helpers.array_of(zone_schema)
          ),
          extras: { required: %w[id name slug links tdwg_code tdwg_level species_count species_count_cumulative] }
        )
      end

      def self.zone_schema
        {
          id: { type: :integer },
          name: { type: :string },
          slug: { type: :string },
          tdwg_code: { type: :string, description: 'The TDWG (WGSRPD) code of the zone' },
          tdwg_level: { type: :integer, description: 'The TDWG level: 1 continent, 2 region, 3 botanical country, 4 basic recording unit' },
          species_count: { type: :integer, description: 'The number of species recorded directly in this zone' },
          species_count_cumulative: {
            type: :integer,
            description: 'The number of distinct species recorded in this zone or in any zone below it (the size of its species collection)'
          },
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
