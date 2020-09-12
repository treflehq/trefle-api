class AddSuggestedIndexes2 < ActiveRecord::Migration[6.0]
  def change
    commit_db_transaction
    add_index :species, [:author], algorithm: :concurrently
    add_index :species, [:genus_name], algorithm: :concurrently
    add_index :species, %i[main_species_id common_name], algorithm: :concurrently
  end
end
