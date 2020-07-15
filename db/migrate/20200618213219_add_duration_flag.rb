class AddDurationFlag < ActiveRecord::Migration[6.0]
  def change
    add_column :species, :duration_fl, :integer, null: false, default: 0, limit: 8
    add_column :species, :propagated_by, :integer, null: false, default: 0, limit: 8
    add_column :species, :growth_months, :integer, null: false, default: 0, limit: 8
    add_column :species, :bloom_months, :integer, null: false, default: 0, limit: 8
    add_column :species, :fruit_months, :integer, null: false, default: 0, limit: 8
  end
end
