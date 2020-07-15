class MigrateMesurements < ActiveRecord::Migration[6.0]
  def up # rubocop:todo Metrics/MethodLength
    q = <<-SQL
      UPDATE species
      SET average_mature_height_value = height_mature_ft,
          average_mature_height_unit = 'ft',
          maximum_height_value = height_at_base_age_max_ft,
          maximum_height_unit = 'ft',
          minimum_root_depth_value = root_depth_minimum_inches,
          minimum_root_depth_unit = 'in',
          minimum_planting_density_value = planting_density_per_acre_minimum,
          minimum_planting_density_unit = 'ac',
          minimum_precipitation_value = precipitation_minimum,
          minimum_precipitation_unit = 'in',
          maximum_precipitation_value = precipitation_maximum,
          maximum_precipitation_unit = 'in',
          minimum_temperature_deg_f = temperature_minimum_deg_f
      WHERE complete_data = true;

      UPDATE species
      SET average_mature_height_value = height_mature_ft,
          average_mature_height_unit = 'ft'
      WHERE height_mature_ft IS NOT NULL;

      UPDATE species
      SET maximum_height_value = height_at_base_age_max_ft,
          maximum_height_unit = 'ft'
      WHERE height_at_base_age_max_ft IS NOT NULL;

      UPDATE species
      SET minimum_root_depth_value = root_depth_minimum_inches,
          minimum_root_depth_unit = 'in'
      WHERE root_depth_minimum_inches IS NOT NULL;

      UPDATE species
      SET minimum_planting_density_value = planting_density_per_acre_minimum,
          minimum_planting_density_unit = 'ac'
      WHERE planting_density_per_acre_minimum IS NOT NULL;

      UPDATE species
      SET minimum_precipitation_value = precipitation_minimum,
          minimum_precipitation_unit = 'in'
      WHERE precipitation_minimum IS NOT NULL;

      UPDATE species
      SET maximum_precipitation_value = precipitation_maximum,
          maximum_precipitation_unit = 'in'
      WHERE precipitation_maximum IS NOT NULL;

      UPDATE species
      SET minimum_temperature_deg_f = temperature_minimum_deg_f
      WHERE temperature_minimum_deg_f IS NOT NULL;

      UPDATE species
      SET rank = 0
      WHERE species.species_type = 'species' AND species.rank IS NULL;

      UPDATE species
      SET rank = 1
      WHERE species.species_type = 'ssp' AND species.rank IS NULL;

      UPDATE species
      SET rank = 2
      WHERE species.species_type = 'var' AND species.rank IS NULL;

      UPDATE species
      SET rank = 3
      WHERE species.species_type = 'form' AND species.rank IS NULL;

      UPDATE species
      SET rank = 4
      WHERE species.species_type = 'hybrid' AND species.rank IS NULL;

      UPDATE species
      SET rank = 5
      WHERE species.species_type = 'subvar' AND species.rank IS NULL;

    SQL

    ActiveRecord::Base.connection.execute(q)

    Species.where.not(temperature_minimum_deg_f: nil).map do |s|
      t = Temperature.from_fahrenheit(s.temperature_minimum_deg_f)
      s.update_columns(minimum_temperature_deg_c: t.celsius) if s.minimum_temperature_deg_c.nil?
    end
  end

  def down
    q = <<-SQL
      UPDATE species
      SET average_mature_height_value = NULL,
          average_mature_height_unit = NULL,
          maximum_height_value = NULL,
          maximum_height_unit = NULL,
          minimum_root_depth_value = NULL,
          minimum_root_depth_unit = NULL,
          minimum_planting_density_value = NULL,
          minimum_planting_density_unit = NULL,
          minimum_precipitation_value = NULL,
          minimum_precipitation_unit = NULL,
          maximum_precipitation_value = NULL,
          maximum_precipitation_unit = NULL,
          minimum_temperature_deg_c = NULL,
          minimum_temperature_deg_f = NULL
      WHERE complete_data = true;
    SQL

    ActiveRecord::Base.connection.execute(q)
  end
end
