class AddSpeciesOtherMetadatas < ActiveRecord::Migration[6.0]
  def change
    add_column :species, :average_height_cm, :integer
  end
end
