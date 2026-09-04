require 'rails_helper'

RSpec.describe SpeciesPhotoHelper, type: :helper do
  describe '#species_photo_src' do
    it 'swaps the plantnet original-size segment for the requested size' do
      url = 'https://bs.plantnet.org/image/o/abc123.jpg'

      expect(helper.species_photo_src(url)).to eq('https://bs.plantnet.org/image/m/abc123.jpg')
    end

    it 'honors an explicit size' do
      url = 'https://bs.plantnet.org/image/o/abc123.jpg'

      expect(helper.species_photo_src(url, size: :s)).to eq('https://bs.plantnet.org/image/s/abc123.jpg')
    end

    it 'returns non-plantnet urls untouched' do
      url = 'https://cdn.example.com/foo.jpg'

      expect(helper.species_photo_src(url)).to eq(url)
    end

    it 'returns blank input as-is' do
      expect(helper.species_photo_src(nil)).to be_nil
      expect(helper.species_photo_src('')).to eq('')
    end
  end

  describe '#species_photo_alt' do
    it 'combines scientific and common name' do
      species = build(:species, scientific_name: 'Abies alba', common_name: 'Silver fir')

      expect(helper.species_photo_alt(species)).to eq('Abies alba (Silver fir)')
    end

    it 'falls back to the scientific name alone when there is no common name' do
      species = build(:species, scientific_name: 'Abies alba', common_name: nil)

      expect(helper.species_photo_alt(species)).to eq('Abies alba')
    end

    it 'returns an empty string for a nil species' do
      expect(helper.species_photo_alt(nil)).to eq('')
    end
  end

  describe '#species_photo_tag' do
    it 'renders a lazy-loaded img with a medium src and meaningful alt text when a photo exists' do
      species = build(:species,
                      scientific_name: 'Abies alba',
                      common_name: 'Silver fir',
                      main_image_url: 'https://bs.plantnet.org/image/o/abc123.jpg')

      node = Nokogiri::HTML.fragment(helper.species_photo_tag(species, css_class: 'species-grid-item-photo')).at_css('img')

      expect(node).not_to be_nil
      expect(node['src']).to eq('https://bs.plantnet.org/image/m/abc123.jpg')
      expect(node['alt']).to eq('Abies alba (Silver fir)')
      expect(node['loading']).to eq('lazy')
      expect(node['decoding']).to eq('async')
      expect(node['class']).to eq('species-grid-item-photo')
      expect(node['width']).to be_present
      expect(node['height']).to be_present
    end

    it 'renders a placeholder with a leaf glyph when the species has no photo' do
      species = build(:species, scientific_name: 'Abies alba', common_name: 'Silver fir', main_image_url: nil)

      fragment = Nokogiri::HTML.fragment(helper.species_photo_tag(species, css_class: 'species-grid-item-photo'))

      expect(fragment.at_css('img')).to be_nil
      placeholder = fragment.at_css('div.species-grid-item-photo.species-grid-item-photo--empty')
      expect(placeholder).not_to be_nil
      expect(placeholder.at_css('svg.fa-leaf')).not_to be_nil
    end
  end
end
