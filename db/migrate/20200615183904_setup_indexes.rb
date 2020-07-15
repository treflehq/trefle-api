class SetupIndexes < ActiveRecord::Migration[6.0]
  def change
    commit_db_transaction
    add_index :plants, [:slug], algorithm: :concurrently
    add_index :species, [:foliage_color], algorithm: :concurrently
    add_index :species, [:slug], algorithm: :concurrently
    add_index :species_images, [:species_id], algorithm: :concurrently
    add_index :synonyms, [:name], algorithm: :concurrently

    remove_index :foreign_sources_plants, name: 'foreign_sources_plants_species_id_index', column: :species_id
  end
end
