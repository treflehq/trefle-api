class AddVegetableType < ActiveRecord::Migration[6.0]
  def change
    add_column :species, :edible_part, :integer, null: false, default: 0
  end
end
