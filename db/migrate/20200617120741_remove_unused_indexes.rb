class RemoveUnusedIndexes < ActiveRecord::Migration[6.0]
  def change
    remove_index :species, name: 'species_synonym_of_id_index'
    remove_index :families, name: 'families_division_order_id_index'
    remove_index :families, name: 'families_major_group_id_index'
    remove_index :division_orders, name: 'division_orders_division_class_id_index'
    remove_index :divisions, name: 'divisions_subkingdom_id_index'
    remove_index :species_proposals, name: 'species_proposals_genus_id_index'
    remove_index :species_proposals, name: 'species_proposals_synonym_of_id_index'
    remove_index :species_proposals, name: 'species_proposals_user_id_index'
    remove_index :subkingdoms, name: 'subkingdoms_kingdom_id_index'
    remove_index :record_corrections, name: 'index_record_corrections_on_user_id'
  end
end
