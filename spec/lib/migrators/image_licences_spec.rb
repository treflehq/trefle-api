require 'rails_helper'

RSpec.describe Migrators::ImageLicences do
  let(:species) { create(:species) }
  let(:fields) { %i[licence licence_url author commercial_use_allowed thumbnail_url] }

  # Rows as the backfill finds them: written before the columns existed.
  let!(:plantnet) do
    SpeciesImage.create!(species: species, image_url: 'https://bs.plantnet.org/image/o/abc',
                         copyright: 'Taken Mar 14, 2022 by Jane  Doe (cc-by-sa)').tap {|i| blank!(i) }
  end
  let!(:kew) do
    SpeciesImage.create!(species: species, image_url: 'https://d2seqvvyy3b8p2.cloudfront.net/a.jpg',
                         copyright: ImageLicence::KEW_COPYRIGHT).tap {|i| blank!(i) }
  end
  let!(:other) do
    SpeciesImage.create!(species: species, image_url: 'https://example.com/a.jpg', copyright: 'Wikipedia 2022')
  end

  def blank!(image)
    image.update_columns(fields.index_with { nil })
  end

  it 'changes nothing on a dry run' do
    result = described_class.run(dry_run: true)

    expect(plantnet.reload.licence).to be_nil
    expect(result.to_h).to include('scanned' => 3, 'to_update' => 2, 'updated' => 0, 'unchanged' => 1)
  end

  it 'fills the fields, counts them per licence, and writes nothing the second time' do
    result = described_class.run(dry_run: false)

    expect(plantnet.reload).to have_attributes(licence: 'CC-BY-SA', author: 'Jane  Doe', commercial_use_allowed: true,
                                               thumbnail_url: 'https://bs.plantnet.org/image/s/abc')
    expect(kew.reload).to have_attributes(licence: 'LicenseRef-All-Rights-Reserved', commercial_use_allowed: false)
    expect(result.to_h).to include(
      'updated' => 2, 'skipped_changed' => 0,
      'by_licence' => { 'CC-BY-SA' => 1, 'LicenseRef-All-Rights-Reserved' => 1, 'unknown' => 1 },
      'commercial_use_allowed' => { 'true' => 1, 'false' => 1, 'nil' => 1 },
      'unrecognised_copyrights' => { 'Wikipedia 2022' => 1 }
    )

    expect(described_class.run(dry_run: false).to_h).to include('to_update' => 0, 'updated' => 0, 'unchanged' => 3)
  end

  it 'skips a row whose copyright changed after it was read' do
    allow(ImageLicence).to receive(:derive).and_wrap_original do |original, **args|
      SpeciesImage.where(id: plantnet.id).update_all(copyright: 'changed') if args[:image_url] == plantnet.image_url
      original.call(**args)
    end

    result = described_class.run(dry_run: false)

    expect(plantnet.reload.licence).to be_nil
    expect(result.to_h).to include('updated' => 1, 'skipped_changed' => 1)
  end
end
