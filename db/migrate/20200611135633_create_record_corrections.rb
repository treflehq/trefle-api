class CreateRecordCorrections < ActiveRecord::Migration[5.2]
  def change
    create_table :record_corrections do |t|
      t.references :record, polymorphic: true
      t.references :user, foreign_key: true
      t.text :correction_json
      t.string :warning_type
      t.integer :change_status, null: false, default: 0
      t.integer :change_type, null: false, default: 0
      t.integer :accepted_by, null: true
      t.text :notes
      t.text :change_notes
      t.timestamps
    end
  end
end
