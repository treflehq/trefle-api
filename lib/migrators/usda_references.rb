module Migrators
  class UsdaReferences

    def self.run
      fs = ForeignSource.find_by_slug('usda')

      Species.where.not(z_leg_usda_name: nil).find_in_batches(batch_size: 100).with_index do |group, batch|
        puts "Processing group ##{batch}"

        group.each do |s|
          ForeignSourcesPlant.where(foreign_source_id: fs.id, record: s).first_or_create!(
            fid: s.z_leg_usda_name,
            species_id: s.id
          )
          s.update(z_leg_usda_name: nil)
        end
      end
    end

  end
end
