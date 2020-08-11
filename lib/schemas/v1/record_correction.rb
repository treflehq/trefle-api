module Schemas
  module V1
    module RecordCorrection

      def self.anyOfEnum(enum:, extras:)
        stringItem = {
          type: "string",
          enum: [*enum, nil]
        }.merge(extras)

        {anyOf: [{ type: :array, items: stringItem }, stringItem]}
      end

      def self.schema
        Helpers.object_of({
          id: { type: :integer },
          accepted_by: { type: :string, nullable: true },
          change_notes: { type: :string, nullable: true },
          change_status: { type: :string },
          change_type: { type: :string },
          correction: { type: :object, nullable: true },
          created_at: { type: :string },
          notes: { type: :string, nullable: true },
          record_id: { type: :integer, nullable: true },
          record_type: { type: :string },
          updated_at: { type: :string },
          user_id: { type: :integer },
          warning_type: { type: :string, nullable: true }
        }, extras: { required: %w[id user_id record_type updated_at created_at change_type change_status] })
      end

      def self.request_body
        Helpers.object_of({
          notes: { type: :string, nullable: true, description: 'Some optional notes you can add. They will be visible to everybody' },
          # change_type: { type: :string, nullable: true },
          source_type: { type: :string, enum: [*::RecordCorrection.source_types.keys, nil], nullable: true, description: 'Where does this data come from ? If "external", you\'ll need to provide the "source_reference" field with the url or the name of the source, such as a wikipedia article, a publication, etc...' },
          source_reference: { type: :string, nullable: true, description: 'The url of the name of an article or a publication for theses changes' },
          correction: correction_body
        })
      end

      def self.correction_body # rubocop:todo Metrics/MethodLength
        Helpers.object_of({
          scientific_name: { type: :string, example: 'Abelmoschus nonexistus' }, # 'Abelmoschus nonexistus',
          rank: { type: :string, enum: [*::Species.ranks.keys, nil], example: 'species' }, # 'species',
          genus: { type: :string, nullable: true, example: ::Genus.last&.name }, # Genus.last.name,
          year: { type: :integer, nullable: true, example: nil }, # nil,
          author: { type: :string, nullable: true, example: 'Moench' }, # 'Moench',
          bibliography: { type: :string, nullable: true, example: nil }, # nil,
          common_name: { type: :string, nullable: true, description: 'The species common name(s) in english. Several values can be separated with "|"', example: 'Okra|Bonnie Green Okra' }, # 'Okra|Bonnie Green Okra Heirloom Clemson Spineless',
          observations: { type: :string, nullable: true, example: 'Vegetal flavour, Medium-yellow flowers' }, # 'Vegetal flavour, Medium-yellow flowers',
          planting_description: { type: :string, nullable: true, description: 'A description on how the plant usually grows' }, # 'Vegetal flavour, Medium-yellow flowers',
          planting_sowing_description: { type: :string, nullable: true, example: 'A description on how to sow the plant' }, # 'Vegetal flavour, Medium-yellow flowers',

          duration: anyOfEnum(enum: ::Species.durations.maps.keys, extras: {nullable: true, description: 'The duration(s) of the species. Several values can be separated with "|"', example: 'annual' }),
          flower_color: anyOfEnum(enum: ::Species.flower_colors.maps.keys, extras: {nullable: true, description: 'The species flower color(s). Several values can be separated with "|"', example: 'yellow' }), # 'yellow',
          flower_conspicuous: { type: :boolean, nullable: true, example: true }, # true,
          foliage_color: anyOfEnum(enum: ::Species.foliage_colors.maps.keys, extras: {nullable: true, description: 'The species foliage color(s). Several values can be separated with "|"', example: 'green|blue' }), # 'green|blue',
          foliage_texture: { type: :string, enum: [*::Species.foliage_textures.keys, nil], nullable: true, example: nil }, # nil,
          leaf_retention: { type: :boolean, nullable: true, example: false }, # nil,
          fruit_color: anyOfEnum(enum: ::Species.fruit_colors.maps.keys, extras: {nullable: true, description: 'The species fruit color(s). Several values can be separated with "|"', example: 'white' }), # nil,
          fruit_conspicuous: { type: :boolean, nullable: true, example: false }, # nil,
          fruit_seed_persistence: { type: :boolean, nullable: true, example: false }, # nil,
          fruit_months: anyOfEnum(enum: ::Species.fruit_months.maps.keys, extras: {nullable: true, description: 'The months when his species have fruits. Several values can be separated by "|"', example: 'jan|feb|mar' }), # 'jan|feb|mar',
          bloom_months: anyOfEnum(enum: ::Species.bloom_months.maps.keys, extras: {nullable: true, description: 'The months when this species blooms. Several values can be separated by "|"', example: nil }), # nil,
          ground_humidity: { type: :integer, nullable: true, description: 'Required humidity of the soil, on a scale from 0 (xerophile) to 10 (subaquatic)', example: nil }, # nil,
          growth_form: { type: :string, nullable: true, example: nil }, # nil,
          growth_habit: { type: :string, nullable: true, example: nil }, # nil,
          growth_months: anyOfEnum(enum: ::Species.growth_months.maps.keys, extras: {nullable: true, description: 'The months when this species grows. Several values can be separated by "|"', example: nil }), # nil,
          growth_rate: { type: :string, nullable: true, example: nil }, # nil,
          edible_part: anyOfEnum(enum: ::Species.edible_parts.maps.keys, extras: {nullable: true, description: 'The edible part of the species (if any). Several values can be separated by "|"', example: 'flowers' }), # 'flowers',
          vegetable: { type: :boolean, nullable: true, example: false }, # nil,
          light: { type: :integer, nullable: true, description: 'Required amount of light, on a scale from 0 (no light, <= 10 lux) to 10 (very intensive insolation, >= 100 000 lux)', example: 8 }, # 8,
          atmospheric_humidity: { type: :integer, nullable: true, description: 'Required relative humidity in the air, on a scale from 0 (<=10%) to 10 (>= 90%)', example: 3 }, # 8,
          adapted_to_coarse_textured_soils: { type: :string, nullable: true, example: nil }, # nil,
          adapted_to_fine_textured_soils: { type: :string, nullable: true, example: nil }, # nil,
          adapted_to_medium_textured_soils: { type: :string, nullable: true, example: nil }, # nil,
          anaerobic_tolerance: { type: :string, nullable: true, example: nil }, # nil,
          average_height_unit: { type: :string, enum: %I[in ft cm m], nullable: true, example: 'cm' }, # 'cm',
          average_height_value: { type: :number, nullable: true, example: '250' }, # '250',
          maximum_height_unit: { type: :string, enum: %I[in ft cm m], nullable: true, example: 'cm' }, # 'cm',
          maximum_height_value: { type: :number, nullable: true, example: '280' }, # '250',
          planting_row_spacing_unit: { type: :string, enum: %I[in ft cm m], nullable: true, example: 'cm' }, # 'cm',
          planting_row_spacing_value: { type: :number, nullable: true, example: '80', description: 'The minimum spacing between each rows of plants' }, # '250',
          planting_spread_unit: { type: :string, enum: %I[in ft cm m], nullable: true, example: 'cm' }, # 'cm',
          planting_spread_value: { type: :number, nullable: true, example: '100', description: 'The average spreading of the plant' }, # '250',
          planting_days_to_harvest: { type: :integer, nullable: true, example: 120 }, # 120,
          maximum_precipitation_unit: { type: :string, enum: %I[in ft mm cm m], nullable: true, example: 'mm' }, # 'cm',
          maximum_precipitation_value: { type: :number, nullable: true, example: '2230' }, # '250',
          minimum_precipitation_unit: { type: :string, enum: %I[in ft mm cm m], nullable: true, example: 'mm' }, # 'cm',
          minimum_precipitation_value: { type: :number, nullable: true, example: '1300' }, # '250',
          minimum_root_depth_unit: { type: :string, enum: %I[in ft cm m], nullable: true, example: 'cm' }, # 'cm',
          minimum_root_depth_value: { type: :number, nullable: true, example: '30' }, # '250',
          ph_maximum: { type: :number, nullable: true, example: nil },  # nil,
          ph_minimum: { type: :number, nullable: true, example: nil },  # nil,
          soil_nutriments: { type: :integer, nullable: true, description: 'Required quantity of nutriments in the soil, on a scale from 0 (oligotrophic) to 10 (hypereutrophic)' },
          soil_salinity: { type: :integer, nullable: true, description: 'Tolerance to salinity, on a scale from 0 (untolerant) to 10 (hyperhaline)' },
          minimum_temperature_deg_c: { type: :number, nullable: true, example: 5, description: 'The minimum required temperature in celcius degrees' }, # nil,
          maximum_temperature_deg_c: { type: :number, nullable: true, example: 20, description: 'The maximum required temperature in celcius degrees' }, # nil,
          soil_texture: { type: :integer, description: 'Required texture of the soil, on a scale from 0 (clay) to 10 (rock)', nullable: true, example: nil }, # nil,
          ligneous_type: { type: :string, enum: [*::Species.ligneous_types.keys, nil], nullable: true, example: nil }, # nil,
          toxicity: { type: :string, enum: [*::Species.toxicities.keys, nil], nullable: true, example: nil } # nil,
        }, extras: { required: %w[scientific_name], description: 'The fields to correct' })
      end
    end
  end
end
