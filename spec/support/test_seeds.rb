# Seeds the test database once per suite run.
#
# Most request/controller specs assume an already-populated database
# (`Kingdom.first`, `Genus.last`, `Species.where(complete_data: true)`...)
# instead of creating their own records. Historically this data came from a
# restored production dump; this module recreates the minimum equivalent
# dataset deterministically so the suite is self-sufficient.
module TestSeeds

  # Index 1 lands on the Abies genus so the suite gets the "Abies alba"
  # species (slug abies-alba) that the corrections specs reference.
  EPITHETS = %w[grandiflora alba uniflora sylvestris officinalis vulgaris].freeze

  def self.seed!
    load Rails.root.join('db', 'botanic_seeds.rb')

    family = Family.first
    genera = [
      Genus.create!(name: 'Abelia', family: family),
      Genus.create!(name: 'Abies', family: family)
    ]
    zones = Zone.order(:id).limit(3).to_a

    EPITHETS.each_with_index do |epithet, i|
      genus = genera[i % genera.size]
      species = Species.create!(
        genus: genus,
        rank: 'species',
        scientific_name: "#{genus.name} #{epithet}",
        author: "Aubin#{i}",
        year: 1900 + i,
        bibliography: 'Sp. Pl.: 1200 (1753)',
        common_name: "Test plant #{i}",
        observations: 'Seeded for the test suite',
        vegetable: true,
        edible_part: %i[fruits leaves],
        duration: %i[annual],
        bloom_months: %i[apr may],
        fruit_months: %i[jun],
        growth_months: %i[mar apr may],
        flower_color: %i[white],
        foliage_color: %i[green],
        fruit_color: %i[red],
        flower_conspicuous: true,
        fruit_conspicuous: true,
        fruit_seed_persistence: true,
        leaf_retention: false,
        status: 'accepted',
        toxicity: 'low',
        foliage_texture: 'medium',
        ligneous_type: 'shrub',
        soil_texture: 'limon',
        growth_form: 'Bunch',
        growth_habit: 'Forb/herb',
        growth_rate: 'Rapid',
        light: 4 + i,
        atmospheric_humidity: 5,
        ground_humidity: 5,
        soil_nutriments: 5,
        soil_salinity: 1,
        ph_minimum: 5.5,
        ph_maximum: 7.2,
        minimum_temperature_deg_c: -5,
        maximum_temperature_deg_c: 35,
        average_height_cm: 120 + i,
        maximum_height_cm: 200 + (i * 10),
        minimum_root_depth_cm: 30,
        minimum_precipitation_mm: 300,
        maximum_precipitation_mm: 1200,
        planting_days_to_harvest: 60 + i,
        planting_row_spacing_cm: 30,
        planting_spread_cm: 40,
        planting_description: 'Grows everywhere tests are run',
        planting_sowing_description: 'Sow directly in the spec file',
        main_image_url: 'https://example.com/image.jpg',
        gbif_score: 50 + i
      )

      # In production main_species is assigned by Migrators::MainSpeciesWorker,
      # not by model callbacks, so mirror that here.
      species.plant&.update_columns(main_species_id: species.id)

      Synonym.create!(record: species, name: "#{genus.name} synonymica#{('a'..'z').to_a[i]}", author: 'L.')
      CommonName.create!(record: species, name: "Common test #{i}", lang: 'en')
      SpeciesDistribution.create!(species: species, zone: zones[i % zones.size])
    end

    raise 'TestSeeds: no complete_data species were generated' if Species.where(complete_data: true).none?
    raise 'TestSeeds: no plant got a main_species' if Plant.where.not(main_species_id: nil).none?
  end
end
