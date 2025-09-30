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
require 'rails_helper'

RSpec.describe SpeciesDistribution, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
