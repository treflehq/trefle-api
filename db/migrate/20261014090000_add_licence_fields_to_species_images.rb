# Structured reuse terms for each image, read from the free-text `copyright`
# the crawlers wrote ("Taken <date> by <author> (cc-by-sa)", "© copyright of
# the Board of Trustees of the Royal Botanic Gardens, Kew."), plus a
# thumbnail where the host serves one. `copyright` stays as it is: these
# columns are derived from it (ImageLicence), never typed by hand.
#
# Additive only: the canary runs it against production before the switch
# and the previous release ignores the new columns. The backfill is a
# separate, journaled run (Migrators::ImageLicencesWorker).
class AddLicenceFieldsToSpeciesImages < ActiveRecord::Migration[8.1]
  def change
    change_table :species_images, bulk: true do |t|
      t.string :licence
      t.string :licence_url
      t.string :author
      t.boolean :commercial_use_allowed
      t.string :thumbnail_url
    end
  end
end
