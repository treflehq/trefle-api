class AddCreatedAtToResources < ActiveRecord::Migration[6.0]
  # rubocop:todo Metrics/MethodLength
  def change # rubocop:todo Metrics/AbcSize # rubocop:todo Metrics/MethodLength # rubocop:todo Metrics/MethodLength # rubocop:todo Metrics/MethodLength
    add_column :kingdoms, :created_at, :datetime
    add_column :division_classes, :created_at, :datetime
    add_column :division_orders, :created_at, :datetime
    add_column :divisions, :created_at, :datetime
    add_column :families, :created_at, :datetime
    add_column :foreign_sources, :created_at, :datetime
    add_column :foreign_sources_plants, :created_at, :datetime
    add_column :genuses, :created_at, :datetime
    add_column :major_groups, :created_at, :datetime
    add_column :plants, :created_at, :datetime
    add_column :species, :created_at, :datetime
    add_column :species_images, :created_at, :datetime
    add_column :subkingdoms, :created_at, :datetime
    add_column :users, :created_at, :datetime

    reversible do |dir|
      dir.up { Kingdom.update_all('created_at = inserted_at') }
      dir.up { DivisionClass.update_all('created_at = inserted_at') }
      dir.up { DivisionOrder.update_all('created_at = inserted_at') }
      dir.up { Division.update_all('created_at = inserted_at') }
      dir.up { Family.update_all('created_at = inserted_at') }
      dir.up { ForeignSource.update_all('created_at = inserted_at') }
      dir.up { ForeignSourcesPlant.update_all('created_at = inserted_at') }
      dir.up { Genus.update_all('created_at = inserted_at') }
      dir.up { MajorGroup.update_all('created_at = inserted_at') }
      dir.up { Plant.update_all('created_at = inserted_at') }
      dir.up { Species.update_all('created_at = inserted_at') }
      dir.up { SpeciesImage.update_all('created_at = inserted_at') }
      dir.up { Subkingdom.update_all('created_at = inserted_at') }
      dir.up { User.update_all('created_at = inserted_at') }
    end
  end
  # rubocop:enable Metrics/MethodLength
end
