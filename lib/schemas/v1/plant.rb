module Schemas
  module V1
    module Plant
      def self.base
        {
          id: { type: :integer },
          common_name: { type: :string, nullable: true }, # "grand fir",
          slug: { type: :string }, # "abies-grandis",
          scientific_name: { type: :string }, # "Abies grandis",
          year: { type: :integer, nullable: true }, # 1833,
          bibliography: { type: :string, nullable: true }, # "Penny Cyclop. 1: 30 (1833)",
          author: { type: :string, nullable: true }, # "(Douglas ex D.Don) Lindl.",
          # status: { type: :string }, @TODO # "Accepted",
          family_common_name: { type: :string, nullable: true }, # "Pine family",
          genus_id: { type: :integer }, # 4,
          main_species_id: { type: :integer, nullable: true }, # 101131,
          vegetable: { type: :boolean, nullable: true }, # false,
          # vegetable_category: { type: :string, nullable: true }, # null,
          observations: { type: :string, nullable: true } # "SW. Canada to N. California",
        }
      end

      def self.light_schema
        Helpers.object_of(
          base.merge({
            links: Helpers.object_of({
              self: { type: :string },
              genus: { type: :string },
              species: { type: :string }
            }, extras: { required: %w[self genus species] })
          }),
          extras: { required: %w[id scientific_name slug links] }
        )
      end

      def self.schema
        Helpers.object_of(
          base.merge({
            main_species: Helpers.schema_href(schema: :species),
            sources: Helpers.schema_array_href(schema: :source),
            links: Helpers.object_of({
              self: { type: :string },
              genus: { type: :string },
              species: { type: :string }
            }, extras: { required: %w[self genus species] })
          }),
          extras: { required: %w[id scientific_name slug links] }
        )
      end
    end
  end
end
