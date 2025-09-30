class RenameNativeStatus < ActiveRecord::Migration[6.0]
  def change
    rename_column :species, :native_status, :z_leg_native_status
  end
end
