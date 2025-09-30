class AddSourcesCountToSpecies < ActiveRecord::Migration[6.0]
  def self.up
    add_column :species, :sources_count, :integer, null: false, default: 0
  end

  def self.down
    remove_column :species, :sources_count
  end
end
