class AddSourcesCountToPlants < ActiveRecord::Migration[6.0]
  def self.up
    add_column :plants, :sources_count, :integer, null: false, default: 0
  end

  def self.down
    remove_column :plants, :sources_count
  end
end
