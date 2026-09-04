# == Schema Information
#
# Table name: species_trends
#
#  id                :integer          not null, primary key
#  species_id        :integer          not null
#  foreign_source_id :integer          not null
#  score             :integer
#  date              :datetime
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
# Indexes
#
#  index_species_trends_on_foreign_source_id  (foreign_source_id)
#  index_species_trends_on_species_id         (species_id)
#

require 'rails_helper'

RSpec.describe SpeciesTrend, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
