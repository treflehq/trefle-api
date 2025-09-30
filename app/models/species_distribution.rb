# == Schema Information
#
# Table name: species_distributions
#
#  id            :bigint           not null, primary key
#  establishment :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  species_id    :bigint           not null
#  zone_id       :bigint           not null
#
# Indexes
#
#  index_species_distributions_on_species_id  (species_id)
#  index_species_distributions_on_zone_id     (zone_id)
#
# Foreign Keys
#
#  fk_rails_...  (species_id => species.id)
#  fk_rails_...  (zone_id => zones.id)
#
class SpeciesDistribution < ApplicationRecord
  belongs_to :zone
  belongs_to :species

  enum establishment: {
    native: 0,
    introduced: 1,
    doubtful: 2,
    absent: 3,
    extinct: 4
  }, _suffix: true

  counter_culture :zone, column_name: 'species_count'

end
