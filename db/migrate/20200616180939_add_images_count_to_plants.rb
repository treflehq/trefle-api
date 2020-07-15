class AddImagesCountToPlants < ActiveRecord::Migration[6.0]
  def self.up
    add_column :plants, :images_count, :integer, null: false, default: 0
  end

  def self.down
    remove_column :plants, :images_count
  end
end
