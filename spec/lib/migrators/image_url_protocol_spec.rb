require 'rails_helper'

RSpec.describe Migrators::ImageUrlProtocol do
  let(:species) { create(:species) }

  before do
    SpeciesImage.create!(species: species, image_url: '//upload.wikimedia.org/a.jpg')
    SpeciesImage.create!(species: species, image_url: '//upload.wikimedia.org/b.jpg')
    SpeciesImage.create!(species: species, image_url: 'https://upload.wikimedia.org/b.jpg')
    species.update_columns(main_image_url: '//upload.wikimedia.org/a.jpg')
  end

  it 'prefixes https and drops a relative link whose https twin exists' do
    result = described_class.run(dry_run: false)

    expect(SpeciesImage.where(species: species).pluck(:image_url)).to contain_exactly(
      'https://upload.wikimedia.org/a.jpg', 'https://upload.wikimedia.org/b.jpg'
    )
    expect(species.reload.main_image_url).to eq('https://upload.wikimedia.org/a.jpg')
    expect(result.to_h).to include(images: 2, main_images: 1, twins_removed: 1)
  end

  it 'changes nothing on a dry run' do
    result = described_class.run(dry_run: true)

    expect(SpeciesImage.where(species: species).count).to eq(3)
    expect(result.to_h).to include(images: 2, main_images: 1, twins_removed: 1)
  end
end
