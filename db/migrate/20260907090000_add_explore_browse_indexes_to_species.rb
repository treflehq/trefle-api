# The explore browse page sorts by completion_ratio and reviewed_at and
# filters by family_name; none of these had an index (~400k rows).
class AddExploreBrowseIndexesToSpecies < ActiveRecord::Migration[8.0]
  # A plain CREATE INDEX takes an ACCESS EXCLUSIVE lock for the whole build,
  # which on a table this size means the API's busiest table stops answering
  # three times in a row during the deploy migration. Build them concurrently
  # instead, as 20260905053000_add_index_on_species_wiki_score already does.
  # CREATE INDEX CONCURRENTLY cannot run inside a transaction.
  disable_ddl_transaction!

  def change
    add_index :species, :completion_ratio, algorithm: :concurrently
    add_index :species, :reviewed_at, algorithm: :concurrently
    add_index :species, :family_name, algorithm: :concurrently
  end
end
