# == Schema Information
#
# Table name: species_distributions
#
#  id            :integer          not null, primary key
#  zone_id       :integer          not null
#  species_id    :integer          not null
#  establishment :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_species_distributions_on_species_id  (species_id)
#  index_species_distributions_on_zone_id     (zone_id)
#

class SpeciesDistribution < ApplicationRecord
  belongs_to :zone
  belongs_to :species

  enum :establishment, {
    native: 0,
    introduced: 1,
    doubtful: 2,
    absent: 3,
    extinct: 4
  }, suffix: true

  counter_culture :zone, column_name: 'species_count'

end
