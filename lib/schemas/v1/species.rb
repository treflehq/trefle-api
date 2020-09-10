module Schemas
  module V1
    module Species # rubocop:todo Metrics/ModuleLength
      def self.base
        {
          id: { type: :integer, description: 'An unique identifier' }, # 101131,
          common_name: { type: :string, nullable: true, description: 'The usual common name, in english, of the species (if any).' }, # "grand fir",
          slug: { type: :string, description: 'An unique human-readable identifier (if you can, prefer to use this over id)' }, # "abies-grandis",
          scientific_name: {
            type: :string,
            description: 'The scientific name follows the [Binomial nomenclature](https://en.wikipedia.org/wiki/Binomial_nomenclature), and represents its genus and its species within the genus, resulting in a single worldwide name for each organism. The scientific name of an infraspecific taxons (ranks below species, such as subspecies, forms, varieties...) is a combination of the name of a species and an infraspecific epithet. A connecting term is used to denote the rank. [See IAPT recommendation](https://www.iapt-taxon.org/nomen/pages/main/art_24.html)'
          }, # "Abies grandis",
          year: { type: :integer, nullable: true, description: 'The first publication year of a valid name of this species. [See author citation](https://en.wikipedia.org/wiki/Author_citation_(botany))' }, # 1833,
          bibliography: { type: :string, nullable: true, description: 'The first publication of a valid name of this species. [See author citation](https://en.wikipedia.org/wiki/Author_citation_(botany))' }, # "Penny Cyclop. 1: 30 (1833)",
          author: { type: :string, nullable: true, description: 'The author(s) of the first publication of a valid name of this species. [See author citation](https://en.wikipedia.org/wiki/Author_citation_(botany))' }, # "(Douglas ex D.Don) Lindl.",
          status: { type: :string, enum: ['accepted', 'unknown', nil], description: 'The acceptance status of this species by IPNI' }, # "Accepted",
          rank: { type: :string, enum: [*::Species.ranks.keys, nil], description: 'The [taxonomic rank](https://en.wikipedia.org/wiki/Taxonomic_rank) of the species' }, # "species",
          family_common_name: { type: :string, nullable: true, description: 'The common name (in english) of the species family' }, # "Pine family",
          family: { type: :string, description: 'The scientific name of the species family' },
          # plant_id: { type: :integer, description: 'The common name (in english) of the species family' }, # 101131,
          genus_id: { type: :integer, description: 'The id of the species genus' }, # 101131,
          genus: { type: :string, description: 'The scientific name of the species genus' },
          image_url: { type: :string, nullable: true, description: 'A main image url of the species' },
          links: Helpers.object_of({
            self: { type: :string, description: 'API endpoint to the species itself' },
            genus: { type: :string, description: 'API endpoint to the species genus' },
            plant: { type: :string, description: 'API endpoint to the species plant' }
          }, extras: { required: %w[self genus plant], description: 'API endpoints to related resources' })
        }
      end

      def self.image_schema(extras:)
        Helpers.array_of({
          id: { type: :integer, description: 'An unique identifier' }, # 101131,
          image_url: { type: :string, description: 'The url of the image' }, # "(Douglas ex D.Don) Lindl.",
          copyright: { type: :string, nullable: true, description: 'A copyright (if any) for the image. Don\'t forget to properly credit the author if you\'re using them' } # "(Douglas ex D.Don) Lindl.",
        }, extras: extras)
      end

      def self.images_schema
        Helpers.object_of({
          flower: image_schema(extras: { description: 'Image(s) of the species flower' }),
          leaf: image_schema(extras: { description: 'Image(s) of the species leaf' }),
          habit: image_schema(extras: { description: 'Image(s) of the species habit' }),
          fruit: image_schema(extras: { description: 'Image(s) of the species fruit' }),
          bark: image_schema(extras: { description: 'Image(s) of the species bark' }),
          other: image_schema(extras: { description: 'Image(s) of the species other ' })
        })
      end

      def self.common_names_schema
        Helpers.object_of(nil, extras: {
          additionalProperties: {
            type: :array,
            items: { type: :string, nullable: true, description: 'TODO' }
          },
          description: 'Common names of the species per language'
        })
      end

      def self.distribution_schema
        Helpers.object_of(nil, extras: {
          deprecated: true,
          additionalProperties: {
            type: :array,
            items: { type: :string, nullable: true, description: 'TODO' }
          },
          description: '(Deprecated) Distribution of the species per establishment'
        })
      end

      def self.distribution_item_schema(extras:)
        Helpers.array_of({
          id: { type: :integer, description: 'An unique identifier' }, # 101131,
          name: { type: :string, description: 'The zone name' },
          slug: { type: :string, description: 'An unique, human readable, identifier' },
          tdwg_code: { type: :string, description: 'The TDWG zone unique code' },
          tdwg_level: { type: :integer, description: 'The TDWG zone level' },
          species_count: { type: :integer, description: 'The number of species in this zone' },
          links: Helpers.object_of({
            self: { type: :string, description: 'API endpoint to the zone itself' },
            species: { type: :string, description: 'API endpoint to the species in this zone' },
            plants: { type: :string, description: 'API endpoint to the plants in this zone' }
          })
        }, extras: extras)
      end

      def self.distributions_schema
        Helpers.object_of({
          native: distribution_item_schema(extras: { description: 'Zones the species is native from' }),
          introduced: distribution_item_schema(extras: { description: 'Zones the species has been introduced' }),
          doubtful: distribution_item_schema(extras: { description: 'Zones the species presence is doubtful' }),
          absent: distribution_item_schema(extras: { description: 'Zones the species is absent and has been wrongly recorded' }),
          extinct: distribution_item_schema(extras: { description: 'Zones the species is extinct' })
        }, extras: {
          description: 'Distribution of the species per establishment'
        })
      end

      def self.light_schema
        Helpers.object_of(
          base.merge({
            synonyms: { type: :array, items: { type: :string, nullable: true, description: 'TODO' }, description: 'The symonyms scientific names' }
          }),
          extras: { required: %w[id rank family genus genus_id scientific_name slug status links], description: 'The symonyms scientific names' }
        )
      end

      # rubocop:todo Metrics/AbcSize
      def self.schema # rubocop:todo Metrics/MethodLength # rubocop:todo Metrics/AbcSize # rubocop:todo Metrics/AbcSize # rubocop:todo Metrics/AbcSize
        Helpers.object_of(
          base.merge({
            duration: {
              type: :array, nullable: true, items: {
                type: :string, nullable: true, enum: [*::Species.durations.maps.keys, nil],
                description: "The plant duration(s), which can be:\n- Annual: plants that live, reproduce, and die in one growing season.\n- Biennial: plants that need two growing seasons to complete their life cycle, normally completing vegetative growth the first year and flowering the second year.\n- Perennial: plants that live for more than two years, with the shoot system dying back to soil level each year.\n"
              },
              description: "The plant duration(s), which can be:\n- Annual: plants that live, reproduce, and die in one growing season.\n- Biennial: plants that need two growing seasons to complete their life cycle, normally completing vegetative growth the first year and flowering the second year.\n- Perennial: plants that live for more than two years, with the shoot system dying back to soil level each year.\n"
            }, # "perrenial",
            edible_part: {
              type: :array, nullable: true, items: {
                type: :string, nullable: true, enum: [*::Species.edible_parts.maps.keys, nil],
                description: 'The plant edible part(s), if any.'
              },
              description: 'The plant edible part(s), if any.'
            }, # "stems",

            edible: { type: :boolean, nullable: true, description: 'Is the species edible ?' },
            vegetable: { type: :boolean, nullable: true, description: 'Is the species a vegetable ?' },
            observations: { type: :string, nullable: true, description: 'Some habit observations on the species' },

            images: images_schema,
            common_names: common_names_schema,
            distribution: distribution_schema,
            distributions: distributions_schema,

            flower: Helpers.object_of({
              color: { type: :array, nullable: true, items: { type: :string, nullable: true, enum: [*::Species.flower_colors.maps.keys, nil], description: 'The flower color(s)' }, description: 'The flower color(s)' }, # "Purple",
              conspicuous: { type: :boolean, nullable: true, description: 'Is the flower visible ?' } # true
            }, extras: { description: 'Flower related fields (the reproductive structure found in flowering plants)' }),

            foliage: Helpers.object_of({
              texture: { type: :string, nullable: true, enum: [*::Species.foliage_textures.keys, nil], description: 'The general texture of the plant’s foliage' }, # "Coarse",
              color: { type: :array, nullable: true, items: { type: :string, nullable: true, enum: [*::Species.foliage_colors.maps.keys, nil], description: 'The leaves color(s)' }, description: 'The leaves color(s)' }, # "Purple",
              leaf_retention: { type: :boolean, nullable: true, description: 'Does the leaves stay all year long ?' } # null,
            }, extras: { description: 'Foliage (or leaves) related fields' }),

            fruit_or_seed: Helpers.object_of({
              conspicuous: { type: :boolean, nullable: true, description: 'Is the fruit visible ?' }, # null,
              color: { type: :array, nullable: true, items: { type: :string, nullable: true, enum: [*::Species.fruit_colors.maps.keys, nil], description: 'The fruit color(s)' }, description: 'The fruit color(s)' }, # "Purple",
              shape: { type: :string, nullable: true, description: 'Fruit shape' }, # null,
              seed_persistence: { type: :boolean, nullable: true, description: 'Are the fruit or seed generally recognized as being persistent on the plant?' } # null
            }, extras: { description: 'Fruit or seed related fields' }),

            specifications: Helpers.object_of({
              # c_n_ratio: { type: :string, nullable: true, description: 'TODO' }, # @TODO "Medium",
              ligneous_type: { type: :string, nullable: true, enum: [*::Species.ligneous_types.keys, nil], description: 'The ligneous type of the woody plant' }, # "species",
              growth_form: { type: :string, nullable: true, description: 'The primary growth form on the landscape in relation to soil stabilization on slopes and streamsides? Each plant species is assigned the single growth form that most enhances its ability to stabilize soil' }, # "Stoloniferous",
              growth_habit: { type: :string, nullable: true, description: 'The general appearance, growth form, or architecture of the plant' }, # "Forb/herb",
              growth_rate: { type: :string, nullable: true, description: 'The relative growth speed of the plant' }, # "Rapid",
              # known_allelopath: { type: :boolean, nullable: true, description: 'TODO' }, @TODO # null,
              # lifespan: { type: :string, nullable: true, description: 'TODO' }, # @TODO "Moderate",
              average_height: Helpers.object_of({
                # ft: { type: :integer, nullable: true, description: 'TODO' }, # 1.5,
                cm: { type: :integer, nullable: true, description: 'The average height of the species, in centimeters' } # "TODO"
              }, extras: { description: 'The average height of the species, in centimeters' }),
              maximum_height: Helpers.object_of({
                # ft: { type: :integer, nullable: true, description: 'TODO' }, # null,
                cm: { type: :integer, nullable: true, description: 'The maximum height of the species, in centimeters' } # "TODO"
              }, extras: { description: 'The maximum height of the species, in centimeters' }),
              nitrogen_fixation: { type: :string, nullable: true, description: 'Capability to fix nitrogen in monoculture' }, # "None",
              shape_and_orientation: { type: :string, nullable: true, description: 'The predominant shape of the species' }, # "Decumbent",
              toxicity: { type: :string, nullable: true, enum: [*::Species.toxicities.keys, nil], description: 'Relative toxicity of the species for humans or animals' } # "None",
            }, extras: { description: 'Species\'s main characteristics' }),

            growth: Helpers.object_of({
              # anaerobic_tolerance: { type: :string, nullable: true, description: 'TODO' }, @TODO # "None",
              # caco_3_tolerance: { type: :string, nullable: true, description: 'TODO' }, @TODO # "Medium",
              # frost_free_days_minimum: { type: :number, nullable: true, description: 'TODO' },@TODO  # 115,
              days_to_harvest: { type: :number, nullable: true, description: 'The average numbers of days required to from planting to harvest' }, # 8,
              description: { type: :string, nullable: true, description: 'A description on how the plant usually grows' }, # 8,
              sowing: { type: :string, nullable: true, description: 'A description on how to sow the plant' }, # 8,
              ph_maximum: { type: :number, nullable: true, description: 'The maximum acceptable soil pH (of the top 30 centimeters of soil) for the plant' }, # 8,
              ph_minimum: { type: :number, nullable: true, description: 'The minimum acceptable soil pH (of the top 30 centimeters of soil) for the plant' }, # 5.4,
              # minimum_planting_density: Helpers.object_of({
              #   per_acre: { type: :number, nullable: true, description: 'TODO' }, # null,
              #   per_sqm: { type: :number, nullable: true, description: 'TODO' } # "TODO"
              # }),
              light: { type: :integer, nullable: true, description: 'Required amount of light, on a scale from 0 (no light, <= 10 lux) to 10 (very intensive insolation, >= 100 000 lux)' },
              atmospheric_humidity: { type: :integer, nullable: true, description: 'Required relative humidity in the air, on a scale from 0 (<=10%) to 10 (>= 90%)' },
              growth_months: { type: :array, nullable: true, items: { type: :string, nullable: true, enum: [*::Species.growth_months.maps.keys, nil], description: 'The most active growth months of the species (usually all year round for perennial plants)' }, description: 'The most active growth months of the species (usually all year round for perennial plants)' },
              bloom_months: { type: :array, nullable: true, items: { type: :string, nullable: true, enum: [*::Species.bloom_months.maps.keys, nil], description: 'The months the species usually blooms' }, description: 'The months the species usually blooms' },
              fruit_months: { type: :array, nullable: true, items: { type: :string, nullable: true, enum: [*::Species.fruit_months.maps.keys, nil], description: 'The months the species usually produces fruits' }, description: 'The months the species usually produces fruits' },

              row_spacing: Helpers.object_of({
                # inches: { type: :number, nullable: true, description: 'TODO' }, # 16,
                cm: { type: :number, nullable: true, description: 'The minimum spacing between each rows of plants, in centimeters' } # "TODO"
              }, extras: { description: 'The minimum spacing between each rows of plants, in centimeters' }),
              spread: Helpers.object_of({
                # inches: { type: :number, nullable: true, description: 'TODO' }, # 16,
                cm: { type: :number, nullable: true, description: 'The average spreading of the plant, in centimeters' } # "TODO"
              }, extras: { description: 'The average spreading of the plant, in centimeters' }),
              minimum_precipitation: Helpers.object_of({
                # inches: { type: :number, nullable: true, description: 'TODO' }, # 16,
                mm: { type: :number, nullable: true, description: 'Minimum precipitation per year, in milimeters per year' } # "TODO"
              }, extras: { description: 'Minimum precipitation per year, in milimeters per year' }),
              maximum_precipitation: Helpers.object_of({
                # inches: { type: :number, nullable: true, description: 'TODO' }, # 55,
                mm: { type: :number, nullable: true, description: 'Maximum precipitation per year, in milimeters per year' } # "TODO"
              }, extras: { description: 'Maximum precipitation per year, in milimeters per year' }),
              minimum_root_depth: Helpers.object_of({
                # inches: { type: :number, nullable: true, description: 'TODO' }, # 10,
                cm: { type: :number, nullable: true, description: 'Minimum depth of soil required for the species, in centimeters. Plants that do not have roots such as rootless aquatic plants have 0' } # "TODO"
              }, extras: { description: 'Minimum depth of soil required for the species, in centimeters. Plants that do not have roots such as rootless aquatic plants have 0' }),
              minimum_temperature: Helpers.object_of({
                deg_f: { type: :number, nullable: true, description: 'The minimum tolerable temperature for the species. In fahrenheit degrees' }, # 10,
                deg_c: { type: :number, nullable: true, description: 'The minimum tolerable temperature for the species. In celsius degrees' } # "TODO"
              }, extras: { description: 'The minimum tolerable temperature for the species. In celsius or fahrenheit degrees' }),
              maximum_temperature: Helpers.object_of({
                deg_f: { type: :number, nullable: true, description: 'The maximum tolerable temperature for the species. In fahrenheit degrees' }, # 10,
                deg_c: { type: :number, nullable: true, description: 'The maximum tolerable temperature for the species. In celsius degrees' } # "TODO"
              }, extras: { description: 'The maximum tolerable temperature for the species. In celsius or fahrenheit degrees' }),
              soil_nutriments: { type: :integer, nullable: true, description: 'Required quantity of nutriments in the soil, on a scale from 0 (oligotrophic) to 10 (hypereutrophic)' },
              soil_salinity: { type: :integer, nullable: true, description: 'Tolerance to salinity, on a scale from 0 (untolerant) to 10 (hyperhaline)' },
              soil_texture: { type: :integer, nullable: true, description: 'Required texture of the soil, on a scale from 0 (clay) to 10 (rock)' },
              soil_humidity: { type: :integer, nullable: true, description: 'Required humidity of the soil, on a scale from 0 (xerophile) to 10 (subaquatic)' }
              # hardiness_zone: { type: :string, nullable: true, description: 'TODO' }, @TODO
              # adaptation: Helpers.object_of({
              #   medium: { type: :boolean, nullable: true, description: 'TODO' }, # true,
              #   fine: { type: :boolean, nullable: true, description: 'TODO' }, # true,
              #   coarse: { type: :boolean, nullable: true, description: 'TODO' } # true
              # })
            }, extras: { description: 'Growing of farming related fields' }),

            synonyms: Helpers.array_of({
              id: { type: :integer, description: 'An unique identifier' }, # 101131,
              name: { type: :string, description: 'The scientific name of the symonym' }, # "(Douglas ex D.Don) Lindl.",
              author: { type: :string, nullable: true, description: 'The author of the symonym' } # "(Douglas ex D.Don) Lindl.",
            }, extras: { description: 'The symonyms scientific names and authors' }),

            sources: Helpers.array_of({
              id: { type: :string, description: 'An unique identifier from the source' }, # 101131,
              name: { type: :string, description: 'The name of the source' }, # "(Douglas ex D.Don) Lindl.",
              citation: { type: :string, nullable: true, description: 'How to cite the source' }, # "(Douglas ex D.Don) Lindl.",
              url: { type: :string, nullable: true, description: 'The link on the source website, or the publication reference' }, # "(Douglas ex D.Don) Lindl.",
              last_update: { type: :string, description: 'The last time the source was checked' } # "(Douglas ex D.Don) Lindl.",
            }, extras: { description: 'The symonyms scientific names and authors' })

          }, extras: { description: '' }),
          extras: { required: %w[id scientific_name slug] }
        )
      end

      def self.filters
        Helpers.object_of(
          ::Api::V1::SpeciesController::FILTERABLE_FIELDS.map do |f|
            [f, { type: :string }]
          end.to_h
        )
      end

      def self.sorts
        Helpers.object_of(
          ::Api::V1::SpeciesController::ORDERABLE_FIELDS.map do |f|
            [f, { type: :string }]
          end.to_h
        )
      end

      def self.filters_not
        Helpers.object_of(
          ::Api::V1::SpeciesController::FILTERABLE_NOT_FIELDS.map do |f|
            [f, { type: :string }]
          end.to_h
        )
      end

      def self.ranges
        Helpers.object_of(
          ::Api::V1::SpeciesController::RANGEABLE_FIELDS.map do |f|
            [f, { type: :string }]
          end.to_h
        )
      end

      # rubocop:enable Metrics/AbcSize
    end
  end
end
