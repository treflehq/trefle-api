class CreateGuestUser < ActiveRecord::Migration[6.0]
  def change
    u = User.where(email: 'guest@trefle.io').first_or_create!(
      password: SecureRandom.urlsafe_base64(32),
      admin: false,
      name: 'Guest',
      organization_name: 'Trefle',
      organization_url: 'https://trefle.io'
    )
    u.confirm
  end
end
