class CreateDataQualitySnapshots < ActiveRecord::Migration[8.0]
  def change
    create_table :data_quality_snapshots do |t|
      t.date :snapshot_on, null: false
      t.string :dimension, null: false # global / rank / family / source
      t.string :dimension_value # e.g. "species", "Rosaceae", "gbif"
      t.string :attribute_name # a species column, or null for the aggregate row
      t.integer :species_count, default: 0, null: false
      t.integer :filled_count, default: 0, null: false
      t.integer :implausible_count, default: 0, null: false
      t.integer :conflict_count, default: 0, null: false
      t.jsonb :details, default: {}

      t.timestamps
    end

    add_index :data_quality_snapshots,
              %i[snapshot_on dimension dimension_value attribute_name],
              unique: true, name: 'idx_quality_snapshots_unique'
  end
end
