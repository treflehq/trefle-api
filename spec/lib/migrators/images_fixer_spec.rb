require 'rails_helper'

RSpec.describe Migrators::ImagesFixer do
  describe '.uri_for' do
    it 'percent-encodes non-ASCII characters so the URL can be parsed by URI' do
      link = 'https://storage.googleapis.com/powop-assets/neotropikey/' \
             'Raddiella esenbeckii Calderón & Soderstr. - 1.jpg'

      uri = described_class.uri_for(link)

      expect { URI.parse(uri) }.not_to raise_error
      expect(uri).to eq(
        'https://storage.googleapis.com/powop-assets/neotropikey/' \
        'Raddiella%20esenbeckii%20Calder%C3%B3n%20&%20Soderstr.%20-%201.jpg'
      )
    end

    it 'upgrades protocol-relative and http links to https' do
      expect(described_class.uri_for('//example.org/a.jpg')).to eq('https://example.org/a.jpg')
      expect(described_class.uri_for('http://example.org/a.jpg')).to eq('https://example.org/a.jpg')
    end

    it 'returns nil untouched' do
      expect(described_class.uri_for(nil)).to be_nil
    end
  end

  describe '.run' do
    let(:species) { create(:species) }

    it 'normalizes a non-ASCII main_image_url instead of crashing' do
      raw_url = 'https://storage.googleapis.com/powop-assets/neotropikey/Calderón.jpg'
      escaped_url = 'https://storage.googleapis.com/powop-assets/neotropikey/Calder%C3%B3n.jpg'
      species.update_columns(main_image_url: raw_url)
      stub_request(:get, escaped_url).to_return(status: 200)

      expect { described_class.run(species.id) }.not_to raise_error

      expect(species.reload.main_image_url).to eq(escaped_url)
    end

    it 'normalizes a non-ASCII species_image URL instead of crashing' do
      raw_url = 'https://storage.googleapis.com/powop-assets/neotropikey/Calderón.jpg'
      escaped_url = 'https://storage.googleapis.com/powop-assets/neotropikey/Calder%C3%B3n.jpg'
      species.species_images.create!(image_url: raw_url)
      stub_request(:get, escaped_url).to_return(status: 200)

      expect { described_class.run(species.id) }.not_to raise_error

      expect(species.reload.species_images.first.image_url).to eq(escaped_url)
    end
  end
end
