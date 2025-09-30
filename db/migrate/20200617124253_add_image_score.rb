class AddImageScore < ActiveRecord::Migration[6.0]
  def change
    add_column :species_images, :score, :integer, default: 0, null: false
  end
end
