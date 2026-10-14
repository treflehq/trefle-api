# Why a record is kept out of the lists, the search and the counts while it
# stays in the database and resolves by its slug: `bryophyte` (no reference
# arbitrates mosses, liverworts and hornworts yet), `fossil` (an extinct
# taxon). NULL, the default, is a listed record. See Species::HIDDEN_REASONS.
#
# Additive only: the canary runs it against production before the switch and
# the previous release ignores the column. No index: the lists read the
# ~93% of rows where it is NULL, a sequential condition the planner already
# folds into the scans it does.
class AddHiddenReasonToSpecies < ActiveRecord::Migration[8.1]
  def change
    add_column :species, :hidden_reason, :string
  end
end
