require 'rails_helper'

RSpec.describe Migrators::SlugsWorker, type: :worker do
  it 'regenerates missing slugs' do
    species = Species.friendly.find('abies-alba')
    species.update_columns(slug: nil)

    described_class.new.perform

    expect(species.reload.slug).to eq('abies-alba')
  end
end
