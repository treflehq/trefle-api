class CreateSpeciesFacts < ActiveRecord::Migration[8.0]
  def change
    create_table :species_facts do |t|
      t.bigint :species_id, null: false
      t.string :attribute_name, null: false
      t.string :source, null: false # foreign_sources slug, or "community"/"unknown"
      t.string :value # normalized string form of the value
      t.decimal :value_numeric # populated when the value is numeric
      t.string :unit
      t.integer :evidence_type, default: 0, null: false # reported/measured/derived/inferred
      t.integer :status, default: 0, null: false # active/superseded/rejected/outranked
      t.string :source_record_id # id of the record at the source (fid)
      t.string :source_url
      t.text :notes # e.g. rejection reason
      t.integer :n_observations
      t.datetime :observed_at

      t.timestamps
    end

    add_index :species_facts, %i[species_id attribute_name]
    add_index :species_facts, %i[attribute_name status]
    # One active fact per (species, attribute, source)
    add_index :species_facts, %i[species_id attribute_name source],
              unique: true, where: 'status = 0', name: 'idx_species_facts_one_active_per_source'
    add_foreign_key :species_facts, :species
  end
end
