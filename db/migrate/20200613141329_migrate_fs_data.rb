class MigrateFsData < ActiveRecord::Migration[6.0]
  def change
    ActiveRecord::Base.connection.execute("UPDATE foreign_sources_plants SET record_type = 'Species', record_id = species_id WHERE record_type IS NULL")
  end
end
