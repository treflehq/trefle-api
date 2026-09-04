require 'rails_helper'

RSpec.describe IconHelper, type: :helper do
  describe '#fa_icon' do
    it 'renders the vendored icon as an inline svg colored via currentColor' do
      fragment = Nokogiri::HTML.fragment(helper.fa_icon('seedling'))
      svg = fragment.at_css('svg')

      expect(svg).not_to be_nil
      expect(svg['fill']).to eq('currentColor')
      expect(svg['class']).to eq('fa-icon fa-seedling')
      expect(svg['aria-hidden']).to eq('true')
    end

    it 'merges extra classes onto the svg' do
      fragment = Nokogiri::HTML.fragment(helper.fa_icon('magic', class: 'has-text-primary'))

      expect(fragment.at_css('svg')['class']).to eq('fa-icon fa-magic has-text-primary')
    end

    it 'reads from the requested style directory' do
      fragment = Nokogiri::HTML.fragment(helper.fa_icon('github', style: :brands))

      expect(fragment.at_css('svg')).not_to be_nil
    end

    it 'preserves the duotone secondary-layer opacity so the duotone look survives' do
      fragment = Nokogiri::HTML.fragment(helper.fa_icon('seedling'))

      expect(fragment.at_css('svg style').text).to include('fa-secondary')
      expect(fragment.at_css('svg .fa-secondary, svg path.fa-secondary')).not_to be_nil
    end
  end
end
