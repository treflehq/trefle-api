class EnableUnaccentExtension < ActiveRecord::Migration[8.1]
  # Accent-insensitive zone search (`/api/v1/distributions?q=reunion` has to
  # find "Réunion"). unaccent ships with PostgreSQL contrib and is a trusted
  # extension since PostgreSQL 13, so the application role can enable it.
  def change
    enable_extension 'unaccent'
  end
end
