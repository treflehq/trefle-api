class AddSponsorshipFieldsToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :sponsored_tier, :string
    add_column :users, :sponsorship_checked_at, :datetime
  end
end
