namespace :dump do # rubocop:todo Metrics/BlockLength
  desc 'Create a database dump'
  task data: :environment do # rubocop:todo Metrics/BlockLength

    def array_value(val)
      v = val&.to_a
      return nil if v.nil? || v.empty?

      v.join('|')
    end

    def convert_species_to_line(sp)
      {
        id: sp.id,
        scientific_name: sp.scientific_name,
        rank: sp.rank,
        genus: sp.genus_name,
        family: sp.family_name,
        year: sp.year,
        author: sp.author,
        bibliography: sp.bibliography,
        common_name: sp.common_name,
        family_common_name: sp.family_common_name,
        image_url: sp.main_image_url,
        # observations: sp.observations,
        flower_color: array_value(sp.flower_color),
        flower_conspicuous: sp.flower_conspicuous,
        foliage_color: array_value(sp.foliage_color),
        foliage_texture: sp.foliage_texture,
        fruit_color: array_value(sp.fruit_color),
        fruit_conspicuous: sp.fruit_conspicuous,
        fruit_months: array_value(sp.fruit_months),
        bloom_months: array_value(sp.bloom_months),
        ground_humidity: sp.ground_humidity,
        growth_form: sp.growth_form,
        growth_habit: sp.growth_habit,
        growth_months: array_value(sp.growth_months),
        growth_rate: sp.growth_rate,
        edible_part: array_value(sp.edible_part),
        vegetable: sp.vegetable,
        edible: sp.edible,
        light: sp.light,
        soil_nutriments: sp.soil_nutriments,
        soil_salinity: sp.soil_salinity,
        planting_sowing_description: sp.planting_sowing_description,
        anaerobic_tolerance: sp.anaerobic_tolerance,
        atmospheric_humidity: sp.atmospheric_humidity,
        average_height_cm: sp.average_height_cm,
        maximum_height_cm: sp.maximum_height_cm,
        minimum_root_depth_cm: sp.minimum_root_depth_cm,
        ph_maximum: sp.ph_maximum,
        ph_minimum: sp.ph_minimum,
        planting_days_to_harvest: sp.planting_days_to_harvest,
        planting_description: sp.planting_description,
        planting_row_spacing_cm: sp.planting_row_spacing_cm,
        planting_spread_cm: sp.planting_spread_cm,
        synonyms: array_value(sp.synonyms.map(&:name)),
        distributions: array_value(sp.zones.map(&:name)),
        common_names: array_value(sp.common_names.where(lang: 'en').map(&:name))
      }
    end

    md = []
    md << <<~DESC

  # Trefle data

  [🌎 Website](https://trefle.io)  •  [🚀 Getting started](https://docs.trefle.io)  •  [📖 API Documentation](https://docs.trefle.io/reference)  •  [💡 Ideas and features](https://github.com/orgs/treflehq/projects/3)  •  [🐛 Issues](https://github.com/orgs/treflehq/projects/2)

  [![View performance data on Skylight](https://badges.skylight.io/status/nz7MAOv6K6ra.svg)](https://oss.skylight.io/app/applications/nz7MAOv6K6ra) [![View performance data on Skylight](https://badges.skylight.io/rpm/nz7MAOv6K6ra.svg)](https://oss.skylight.io/app/applications/nz7MAOv6K6ra) [![View performance data on Skylight](https://badges.skylight.io/problem/nz7MAOv6K6ra.svg)](https://oss.skylight.io/app/applications/nz7MAOv6K6ra) [![View performance data on Skylight](https://badges.skylight.io/typical/nz7MAOv6K6ra.svg)](https://oss.skylight.io/app/applications/nz7MAOv6K6ra)

  This is the repository for the [Trefle](https://trefle.io) data.

  > This dump has been generated on #{Date.today.to_s}

  ## Structure

  The database dump is a tab-sperated text file with the following rows:

DESC

    CSV.open("../trefle-data/species.csv", 'wb', headers: true, col_sep: "\t") do |csv|
      keys = convert_species_to_line(Species.first).keys

      csv << keys

      md << keys.map{|e| "- #{e}"}.join("\n")

      Species.find_in_batches.with_index do |group, batch|
        puts "Dumping group ##{batch}"
        Species.where(id: group.map(&:id)).preload(:synonyms, :zones, :common_names, genus: :family).each do |sp|
          # next if (sp&.completion_ratio || 0) < 20

          csv << convert_species_to_line(sp).values
        end
      end
    end

    File.write('../trefle-data/README.md', md.join("\n"))

  end
end
