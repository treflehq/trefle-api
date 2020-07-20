class AddBetterFiltersIndexes < ActiveRecord::Migration[6.0]
  def change
    commit_db_transaction
    add_index :species, [:average_height_cm], algorithm: :concurrently
    add_index :species, [:minimum_precipitation_mm], algorithm: :concurrently
    add_index :species, [:minimum_root_depth_cm], algorithm: :concurrently
    add_index :species, [:planting_row_spacing_cm], algorithm: :concurrently
    add_index :species, [:planting_spread_cm], algorithm: :concurrently
  end
end
