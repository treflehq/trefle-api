class AddPlantingColumns < ActiveRecord::Migration[6.0]
  def change
    add_column :species, :planting_description, :text
    add_column :species, :planting_sowing_description, :text
    add_column :species, :planting_days_to_harvest, :integer
    add_column :species, :planting_row_spacing_cm, :integer
    add_column :species, :planting_spread_cm, :integer
  end
end
