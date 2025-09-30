class AddMeasurementsColumns < ActiveRecord::Migration[6.0]
  def change
    # add_column :things, :total_length_value, :decimal, default: 0
    # add_column :things, :total_length_unit, :string, limit: 12, default: "cm"

    # height_mature_ft
    add_column :species, :average_mature_height_value, :decimal
    add_column :species, :average_mature_height_unit, :string, limit: 12

    # height_at_base_age_max_ft
    add_column :species, :maximum_height_value, :decimal
    add_column :species, :maximum_height_unit, :string, limit: 12

    # root_depth_minimum_inches
    add_column :species, :minimum_root_depth_value, :decimal
    add_column :species, :minimum_root_depth_unit, :string, limit: 12

    # planting_density_per_acre_minimum
    add_column :species, :minimum_planting_density_value, :decimal
    add_column :species, :minimum_planting_density_unit, :string, limit: 12

    # precipitation_minimum
    add_column :species, :minimum_precipitation_value, :decimal
    add_column :species, :minimum_precipitation_unit, :string, limit: 12

    # precipitation_maximum
    add_column :species, :maximum_precipitation_value, :decimal
    add_column :species, :maximum_precipitation_unit, :string, limit: 12

    # temperature_minimum_deg_f
    add_column :species, :minimum_temperature_deg_f, :decimal
    add_column :species, :minimum_temperature_deg_c, :decimal
    add_column :species, :maximum_temperature_deg_f, :decimal
    add_column :species, :maximum_temperature_deg_c, :decimal

    add_column :species, :rank, :integer
  end
end
