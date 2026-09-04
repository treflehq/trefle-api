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

require 'rails_helper'

RSpec.describe SpeciesDistribution, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
