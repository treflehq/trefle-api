class CreateCommonNames < ActiveRecord::Migration[6.0]
  def change
    create_table :common_names do |t|
      t.references :record, polymorphic: true, null: false
      t.string :name
      t.string :lang

      t.timestamps
    end
  end
end
