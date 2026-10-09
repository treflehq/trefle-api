class AddIndexOnSynonymsLowerName < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  # Name resolution falls back to a case-insensitive lookup on synonyms
  # (`record_type = 'Species' AND lower(name) = ?`): the TRY import's
  # NameResolver, and any client spelling a name with different casing. The
  # only index is on the raw column, so each of those lookups is a sequential
  # scan of ~840k rows. Measured on a restore of the 2026-10-09 production
  # dump: 40 ms before, 0.02 ms after. An import resolving ~87k names with up
  # to a dozen lookups each spends hours in that scan.
  #
  # Same shape as 20260914130239_add_index_on_species_lower_scientific_name:
  # CONCURRENTLY so the table stays writable, and an explicit ANALYZE because
  # the planner has no statistics on the new expression until it runs.
  def up
    add_index :synonyms, 'record_type, lower(name)', name: 'index_synonyms_on_record_type_and_lower_name',
                                                     algorithm: :concurrently
    execute 'ANALYZE synonyms'
  end

  def down
    remove_index :synonyms, name: 'index_synonyms_on_record_type_and_lower_name', algorithm: :concurrently
  end
end
