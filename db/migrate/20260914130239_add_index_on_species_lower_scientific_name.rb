class AddIndexOnSpeciesLowerScientificName < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  # Api::V1::SpeciesController and Api::V1::PlantsController#collection filter
  # with `where("lower(scientific_name) IN (?)", ...)` (Scopes::Species
  # filter_by_scientific_name), but the existing unique index
  # (species_scientific_name_index) is on the raw column, so it can't satisfy
  # a query wrapped in `lower(...)` -- every lookup by name is a sequential
  # scan on a 489k-row table (Sentry API-4M). A plain btree functional index
  # on the expression fixes it; CONCURRENTLY so the build doesn't take an
  # ACCESS EXCLUSIVE lock on the table (see 20260905053000, 20260907090000 --
  # CREATE INDEX CONCURRENTLY cannot run inside a transaction, hence
  # disable_ddl_transaction!).
  #
  # `up`/`down` instead of `change`: CREATE INDEX CONCURRENTLY doesn't update
  # planner statistics, and autovacuum's analyze threshold is a
  # row-modification count, not triggered by a new index -- without an
  # explicit ANALYZE the planner keeps costing the *old* plan (backward scan
  # on species_gbif_score_idx with a row-by-row filter) as cheaper than the
  # new index, because it has no stats on the indexed expression yet. Measured
  # on a full production-size restore (489,358 rows): the equality lookup
  # went from 465ms (seq-scan-shaped plan, before) to 60.8s (planner still
  # picked the *old* plan against the *new* index, stats stale) to 0.5ms
  # (same query, right after `ANALYZE species`) -- the ANALYZE isn't
  # optional. `execute` isn't auto-reversible, which is why this can't stay a
  # `change` method.
  def up
    add_index :species, 'lower(scientific_name)', name: 'index_species_on_lower_scientific_name', algorithm: :concurrently
    execute 'ANALYZE species'
  end

  def down
    remove_index :species, name: 'index_species_on_lower_scientific_name', algorithm: :concurrently
  end
end
