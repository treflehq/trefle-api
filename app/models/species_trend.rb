# == Schema Information
#
# Table name: species_trends
#
#  id                :bigint           not null, primary key
#  date              :datetime
#  score             :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  foreign_source_id :bigint           not null
#  species_id        :bigint           not null
#
# Indexes
#
#  index_species_trends_on_foreign_source_id  (foreign_source_id)
#  index_species_trends_on_species_id         (species_id)
#
# Foreign Keys
#
#  fk_rails_...  (foreign_source_id => foreign_sources.id)
#  fk_rails_...  (species_id => species.id)
#
class SpeciesTrend < ApplicationRecord
  belongs_to :species
  belongs_to :foreign_source

end
