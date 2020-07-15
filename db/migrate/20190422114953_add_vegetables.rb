class AddVegetables < ActiveRecord::Migration[5.2]
  def change
    # Cf. https://www.wikiwand.com/en/List_of_vegetables

    add_column :plants, :vegetable, :boolean, null: false, default: false

    #  herbs, spices, cereals
    add_column :plants, :vegetable_category, :string
    add_column :plants, :observations, :text
    add_column :species, :observations, :text
    add_column :species, :vegetable, :boolean
    add_column :species, :edible, :boolean
  end
end
