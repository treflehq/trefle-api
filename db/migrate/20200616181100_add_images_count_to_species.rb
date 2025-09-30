class AddImagesCountToSpecies < ActiveRecord::Migration[6.0]
  def self.up
    add_column :species, :images_count, :integer, null: false, default: 0
  end

  def self.down
    remove_column :species, :images_count
  end
end
