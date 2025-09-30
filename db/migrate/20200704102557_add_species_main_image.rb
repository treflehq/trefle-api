class AddSpeciesMainImage < ActiveRecord::Migration[6.0]
  def change
    add_column :species, :main_image_url, :string
  end
end
