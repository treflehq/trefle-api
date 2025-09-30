class CleanupColumns < ActiveRecord::Migration[6.0]
  def change # rubocop:todo Metrics/MethodLength
    q = <<-SQL
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

    SQL

    ActiveRecord::Base.connection.execute(q)

    Species.where.not(temperature_minimum_deg_f: nil).map do |s|
      t = Temperature.from_fahrenheit(s.temperature_minimum_deg_f)
      s.update_columns(minimum_temperature_deg_c: t.celsius) if s.minimum_temperature_deg_c.nil?
    end
  end
end
