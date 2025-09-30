module Migrators
  class Zones

    def self.run
      zones = JSON.parse(File.read("#{Rails.root}/_openfarm/codes.json"))
      zones.each do |z|
        create_zone(z)
      end
      SpeciesDistribution.counter_culture_fix_counts
    end

    def self.create_zone(z)
      zone = Zone.where(tdwg_code: z['code']).first_or_create(
        name: z['name'],
        tdwg_level: z['level']
      )

      zone.update(parent_id: Zone.find_by_tdwg_code(z['parent']).id) if z['parent']
      zone
    end

  end
end
