class AddPlantsMetadata < ActiveRecord::Migration[5.2]
  def change
    add_column :plants, :species_count, :integer
    add_column :plants, :completion_ratio, :integer
    add_column :plants, :reviewed_at, :datetime
    add_column :species, :reviewed_at, :datetime
  end
end
