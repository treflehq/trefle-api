class AddSpeciesCountToZones < ActiveRecord::Migration[6.0]
  def change
    add_column :zones, :species_count, :integer, null: false, default: 0
  end
end
