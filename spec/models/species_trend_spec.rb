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
  let(:species) { Species.friendly.find('abies-alba') }
  let(:foreign_source) { ForeignSource.find_by!(name: 'GBIF') }

  it 'belongs to a species and a foreign source' do
    trend = SpeciesTrend.create!(species: species, foreign_source: foreign_source, score: 42, date: Time.zone.today)

    expect(trend.species).to eq(species)
    expect(trend.foreign_source).to eq(foreign_source)
    expect(trend.score).to eq(42)
  end
end
