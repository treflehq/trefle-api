class CreateSpeciesTrends < ActiveRecord::Migration[6.0]
  def change
    create_table :species_trends do |t|
      t.references :species, null: false, foreign_key: true
      t.references :foreign_source, null: false, foreign_key: true
      t.integer :score
      t.datetime :date

      t.timestamps
    end
  end
end
