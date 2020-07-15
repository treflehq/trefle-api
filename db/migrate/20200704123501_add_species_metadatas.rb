class AddSpeciesMetadatas < ActiveRecord::Migration[6.0]
  def change
    add_column :species, :maximum_height_cm, :integer
    add_column :species, :maximum_precipitation_mm, :integer
    add_column :species, :minimum_precipitation_mm, :integer
    add_column :species, :minimum_root_depth_cm, :integer
    add_column :species, :genus_name, :string
    add_column :species, :family_name, :string
  end
end
