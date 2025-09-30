class AddHardinessAndZones < ActiveRecord::Migration[6.0]
  def change
    add_column :species, :hardiness_zone, :integer
  end
end
