class AddLicenceToForeignSources < ActiveRecord::Migration[8.0]
  def change
    # Machine-readable upstream licence for this source's data (#318).
    # SPDX identifier where one exists (CC-BY-4.0, CC0-1.0), free text
    # otherwise. NULL means unverified — never guessed.
    # Backfill: Migrators::SourceLicencesWorker.
    add_column :foreign_sources, :licence, :string
    add_column :foreign_sources, :licence_url, :string
  end
end
