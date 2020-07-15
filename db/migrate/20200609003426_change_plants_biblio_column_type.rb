class ChangePlantsBiblioColumnType < ActiveRecord::Migration[5.2]
  def change
    change_column :plants, :bibliography, :text
  end
end
