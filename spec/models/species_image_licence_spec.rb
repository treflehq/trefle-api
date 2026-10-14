require 'rails_helper'

RSpec.describe SpeciesImage do
  let(:species) { create(:species) }

  it 'derives the licence fields when a crawler creates an image' do
    image = described_class.create!(
      species: species, image_url: 'https://bs.plantnet.org/image/o/abc123',
      copyright: 'Taken Mar 14, 2022 by Jane Doe (cc-by-nc)'
    )

    expect(image.reload).to have_attributes(
      licence: 'CC-BY-NC', author: 'Jane Doe', commercial_use_allowed: false,
      thumbnail_url: 'https://bs.plantnet.org/image/s/abc123'
    )
  end

  it 'follows the copyright when it changes, and ignores a hand-set licence' do
    image = described_class.create!(species: species, image_url: 'https://example.com/a.jpg', copyright: 'unknown')
    expect(image.licence).to be_nil

    image.update!(copyright: 'Taken Mar 14, 2022 by Jane Doe (cc-by-sa)', licence: 'CC0-1.0')
    expect(image.reload).to have_attributes(licence: 'CC-BY-SA', commercial_use_allowed: true)
  end

  it 'finds the row behind a main image url, preferring the species own' do
    other = create(:species)
    url = 'https://bs.plantnet.org/image/o/feed'
    theirs = described_class.create!(species: other, image_url: url, copyright: 'x')
    ours = described_class.create!(species: species, image_url: url, copyright: 'x')

    expect(described_class.for_url(url, species_id: species.id)).to eq(ours)
    expect(described_class.for_url(url)).to eq(theirs)
    expect(described_class.for_url(nil)).to be_nil
  end
end
