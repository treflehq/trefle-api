class AddMainImageUrlToPlant < ActiveRecord::Migration[6.0]
  def change
    add_column :plants, :main_image_url, :string
  end
end
