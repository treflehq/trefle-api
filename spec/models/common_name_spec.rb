# == Schema Information
#
# Table name: common_names
#
#  id          :integer          not null, primary key
#  record_type :string           not null
#  record_id   :integer          not null
#  name        :string
#  lang        :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_common_names_on_record_type_and_record_id  (record_type,record_id)
#

require 'rails_helper'

RSpec.describe CommonName, type: :model do
  let(:species) { Species.friendly.find('abies-alba') }

  it 'attaches to a polymorphic record' do
    common_name = CommonName.create!(record: species, name: 'Silver fir', lang: 'en')

    expect(common_name.record).to eq(species)
    expect(species.common_names).to include(common_name)
  end

  it 'rejects a duplicate name for the same record and language' do
    CommonName.create!(record: species, name: 'Silver fir', lang: 'en')
    duplicate = CommonName.new(record: species, name: 'Silver fir', lang: 'en')

    expect(duplicate.valid?).to be(false)
    expect(duplicate.errors[:name]).to be_present
  end

  it 'allows the same name for the same record in a different language' do
    CommonName.create!(record: species, name: 'Silver fir', lang: 'en')
    other_lang = CommonName.new(record: species, name: 'Silver fir', lang: 'fr')

    expect(other_lang.valid?).to be(true)
  end
end
