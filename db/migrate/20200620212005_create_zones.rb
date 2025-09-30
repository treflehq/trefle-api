class CreateZones < ActiveRecord::Migration[6.0]
  def change
    create_table :zones do |t|
      t.string :name, null: false
      t.string :feature
      t.string :tdwg_code
      t.integer :tdwg_level

      t.timestamps
    end
  end
end
