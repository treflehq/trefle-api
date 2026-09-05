class AddIndexOnSpeciesWikiScore < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    # Explore::SpeciesController#index sorts the whole table with
    # `Species.all.order(wiki_score: :desc)` and no WHERE clause — a plain
    # btree index lets Postgres satisfy that ORDER BY/LIMIT/OFFSET directly
    # instead of a sequential scan + (disk-spilling, on deep pages) sort.
    # A plain ascending index (default NULLS LAST) is scanned backwards to
    # satisfy DESC, which yields NULLS FIRST — Postgres's own default for
    # `ORDER BY ... DESC` — so no explicit `order:` index option is needed.
    add_index :species, :wiki_score, algorithm: :concurrently
  end
end
