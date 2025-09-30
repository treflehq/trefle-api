class AddZoneSlug < ActiveRecord::Migration[6.0]
  def change
    add_column :zones, :slug, :string
  end
end
