module Schemas
  module V1
    module Plant
      def self.base
        {
          id: { type: :integer },
          # "grand fir"
          common_name: { type: :string, nullable: true, description: 'The common name of the main species, in english, or in the language of the `lang` parameter.' },
          common_name_lang: {
            type: :string, nullable: true,
            description: 'Only with the `lang` parameter: the ISO 639-1 code of the language `common_name` is in (see the species `common_name_lang`).'
          },
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
