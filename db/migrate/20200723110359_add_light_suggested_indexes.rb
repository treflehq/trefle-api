class AddLightSuggestedIndexes < ActiveRecord::Migration[6.0]
  def change
    commit_db_transaction
    add_index :species, [:common_name], algorithm: :concurrently
    add_index :species, [:light], algorithm: :concurrently
    add_index :species, %i[main_species_id gbif_score], algorithm: :concurrently
    add_index :species, [:maximum_height_cm], algorithm: :concurrently
    add_index :species, [:minimum_temperature_deg_f], algorithm: :concurrently
    add_index :species, [:planting_days_to_harvest], algorithm: :concurrently
  end
end
