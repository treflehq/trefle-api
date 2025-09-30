class AddCopyrightToForeignSources < ActiveRecord::Migration[5.2]
  def change
    add_column :foreign_sources, :copyright_template, :text
    add_column :species_images, :image_type, :string
    add_column :species_images, :copyright, :text
  end
end
