class AddSpeciesIndexesAgain < ActiveRecord::Migration[6.0]
  def changecommit_db_transaction
    commit_db_transaction
    add_index :species, [:edible_part], algorithm: :concurrently
    add_index :species, [:vegetable], algorithm: :concurrently
    add_index :plants, [:main_species_gbif_score], algorithm: :concurrently
    add_index :species, [:gbif_score], algorithm: :concurrently
  end
end
