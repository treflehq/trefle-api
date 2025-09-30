class RemoveUnitsColumns < ActiveRecord::Migration[6.0]
  def change
    remove_column :species, :average_mature_height_unit
    remove_column :species, :average_mature_height_value
    remove_column :species, :maximum_precipitation_unit
    remove_column :species, :maximum_precipitation_value
    remove_column :species, :minimum_planting_density_unit
    remove_column :species, :minimum_planting_density_value
    remove_column :species, :minimum_precipitation_unit
    remove_column :species, :minimum_precipitation_value
    remove_column :species, :minimum_root_depth_unit
    remove_column :species, :minimum_root_depth_value
    remove_column :species, :species_type
    remove_column :species, :synonym_of_id
    remove_column :plants, :vegetable_category
    remove_column :plants, :usda_name
  end
end
