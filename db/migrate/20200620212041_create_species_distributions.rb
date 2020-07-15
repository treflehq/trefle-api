class CreateSpeciesDistributions < ActiveRecord::Migration[6.0]
  def change
    create_table :species_distributions do |t|
      t.references :zone, null: false, foreign_key: true
      t.references :species, null: false, foreign_key: true
      t.integer :establishment

      t.timestamps
    end
  end
end
