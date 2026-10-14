require 'rails_helper'

RSpec.describe Migrators::ImageLicencesWorker do
  let(:image) do
    create(:species_image, image_url: 'https://bs.plantnet.org/image/o/abc',
                           copyright: 'Taken Mar 14, 2022 by Jane Doe (cc-by-nc)')
  end

  before { image.update_columns(licence: nil, commercial_use_allowed: nil) }

  it 'journals a dry run without writing' do
    described_class.new.perform

    run = DataRun.find_by(runnable: described_class.name)
    expect(run).to have_attributes(dry_run: true, status: 'completed', kind: 'migration')
    expect(run.report['by_licence']).to eq('CC-BY-NC' => 1)
    expect(image.reload.licence).to be_nil
  end

  it 'journals the real run' do
    described_class.new.perform(false)

    run = DataRun.find_by(runnable: described_class.name)
    expect(run.dry_run).to be(false)
    expect(run.report['updated']).to eq(1)
    expect(image.reload).to have_attributes(licence: 'CC-BY-NC', commercial_use_allowed: false)
  end
end
