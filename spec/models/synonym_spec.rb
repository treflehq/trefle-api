# == Schema Information
#
# Table name: synonyms
#
#  id          :integer          not null, primary key
#  record_type :string           not null
#  record_id   :integer          not null
#  name        :string
#  author      :string
#  notes       :text
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_synonyms_on_name                       (name)
#  index_synonyms_on_record_type_and_record_id  (record_type,record_id)
#

require 'rails_helper'

RSpec.describe Synonym, type: :model do
  let(:species) { Species.friendly.find('abies-alba') }

  it 'requires a name' do
    synonym = Synonym.new(record: species, name: nil)

    expect(synonym.valid?).to be(false)
    expect(synonym.errors[:name]).to be_present
  end

  it 'rejects a name that duplicates an existing synonym' do
    Synonym.create!(record: species, name: 'Abies pectinata')
    duplicate = Synonym.new(record: species, name: 'Abies pectinata')

    expect(duplicate.valid?).to be(false)
    expect(duplicate.errors[:name]).to be_present
  end

  it "rejects a name identical to its record's scientific name" do
    synonym = Synonym.new(record: species, name: species.scientific_name)

    expect(synonym.valid?).to be(false)
    expect(synonym.errors[:name]).to include('Must be different than the record')
  end
end
