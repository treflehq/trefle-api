class AddSpeciesCountCumulativeToZones < ActiveRecord::Migration[8.1]
  # `species_count` is the number of species recorded directly in a zone
  # (kept live by counter_culture on species_distributions). A continent or
  # region has almost none: the records sit on its level 3 and 4 children, so
  # Europe read lower than France. `species_count_cumulative` is the number of
  # distinct species recorded in the zone or any of its descendants, i.e. the
  # size of /api/v1/distributions/:id/species. It is recomputed by
  # Migrators::CountersWorker (Zone.fix_cumulative_counts).
  def change
    add_column :zones, :species_count_cumulative, :integer, default: 0, null: false
  end
end
