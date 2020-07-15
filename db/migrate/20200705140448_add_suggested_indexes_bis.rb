class AddSuggestedIndexesBis < ActiveRecord::Migration[6.0]
  def change
    # commit_db_transaction
    # add_index :foreign_sources_plants, [:fid], algorithm: :concurrently
    # add_index :old_species, [:complete_data], algorithm: :concurrently
    # add_index :old_species, [:family_common_name], algorithm: :concurrently
    # add_index :old_species, [:id], algorithm: :concurrently
    # add_index :old_species, [:main_species_id], algorithm: :concurrently
    # add_index :old_species, [:temperature_minimum_deg_f], algorithm: :concurrently
    # add_index :species, [:token], algorithm: :concurrently
    # add_index :species, [:full_token], algorithm: :concurrently
  end
end
