module Migrators
  class Metrics

    def self.run
      Species
        .where(maximum_height_cm: nil)
        .find_each do |s|

          s.update_columns(
            maximum_height_cm: s&.maximum_height&.convert_to('cm')&.value&.to_i || s&.average_height&.convert_to('cm')&.value&.to_i,
            average_height_cm: s&.average_height&.convert_to('cm')&.value&.to_i || s&.maximum_height&.convert_to('cm')&.value&.to_i,
            maximum_precipitation_mm: s&.maximum_precipitation&.convert_to('mm')&.value&.to_i,
            minimum_precipitation_mm: s&.minimum_precipitation&.convert_to('mm')&.value&.to_i,
            minimum_root_depth_cm: s&.minimum_root_depth&.convert_to('cm')&.value&.to_i,
            genus_name: s&.genus&.name,
            family_name: s&.genus&.family&.name
          )

        end
    end

  end
end
