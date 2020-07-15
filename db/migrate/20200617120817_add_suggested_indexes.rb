class AddSuggestedIndexes < ActiveRecord::Migration[6.0]
  def change
    commit_db_transaction
    add_index :species, [:family_common_name], algorithm: :concurrently
    add_index :species, [:flower_conspicuous], algorithm: :concurrently
  end
end
