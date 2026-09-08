# The explore browse page sorts by completion_ratio and reviewed_at and
# filters by family_name; none of these had an index (~400k rows).
class AddExploreBrowseIndexesToSpecies < ActiveRecord::Migration[8.0]
  def change
    add_index :species, :completion_ratio
    add_index :species, :reviewed_at
    add_index :species, :family_name
  end
end
