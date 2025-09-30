class AddScores < ActiveRecord::Migration[6.0]
  def change
    add_column :species, :gbif_score, :integer, null: false, default: 0
    add_column :plants, :main_species_gbif_score, :integer, null: false, default: 0
  end
end
