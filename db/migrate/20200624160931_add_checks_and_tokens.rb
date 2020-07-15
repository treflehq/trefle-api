class AddChecksAndTokens < ActiveRecord::Migration[6.0]
  def change
    add_column :species, :checked_at, :datetime
    add_column :species, :token, :text
    add_column :species, :full_token, :text
  end
end
