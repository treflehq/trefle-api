class AddPartToImage < ActiveRecord::Migration[6.0]
  def change
    add_column :species_images, :part, :integer
  end
end
