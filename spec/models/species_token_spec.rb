require 'rails_helper'

RSpec.describe Species, 'token uniqueness' do
  let(:genus) { create(:genus) }

  it 'refuses to create a near-duplicate of an existing name' do
    create(:species, scientific_name: "#{genus.name} × handelii", rank: :hybrid, genus: genus)
    twin = build(:species, scientific_name: "#{genus.name} handelii", rank: :species, genus: genus)

    expect(twin).not_to be_valid
    expect(twin.errors[:token]).not_to be_empty
  end

  it 'still creates an unrelated name' do
    create(:species, scientific_name: "#{genus.name} handelii", genus: genus)

    expect(build(:species, scientific_name: "#{genus.name} otherii", genus: genus)).to be_valid
  end
end
