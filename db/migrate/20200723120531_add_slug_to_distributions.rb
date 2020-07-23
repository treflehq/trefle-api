class AddSlugToDistributions < ActiveRecord::Migration[6.0]
  def change
    add_column :zones, :parent_id, :integer
  end
end
