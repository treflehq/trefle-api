require 'rails_helper'

# Guards the WCAG AA promise from #235: the brand accent declared in
# sections/_variables.scss must stay readable everywhere it carries text —
# as a link/icon color on a white background, and as the fill behind the
# white text Bulma picks for solid buttons, badges, active pagination and
# the sidebar's active menu item. Parses the real SCSS file instead of
# duplicating hex values here, so a future color change that regresses
# contrast fails this spec instead of silently shipping.
RSpec.describe 'Color palette contrast' do
  let(:wcag_aa_normal_text) { 4.5 }
  let(:variables_path) { Rails.root.join('app/assets/javascripts/sections/_variables.scss') }
  let(:variables) { parse_scss_variables(variables_path) }

  def parse_scss_variables(path)
    raw = {}
    File.readlines(path).each do |line|
      match = line.match(/^\$([\w-]+):\s*(.+?);/)
      raw[match[1]] = match[2].strip if match
    end

    resolved = {}
    raw.each_key {|name| resolved[name] = resolve_scss_value(name, raw, resolved) }
    resolved
  end

  def resolve_scss_value(name, raw, resolved)
    return resolved[name] if resolved.key?(name)

    value = raw.fetch(name)
    reference = value.match(/\A\$([\w-]+)\z/)
    hex = reference ? resolve_scss_value(reference[1], raw, resolved) : value

    hex.delete('#').sub(/f{2}\z/i, '') # 8-digit "…ff" alpha suffix -> plain 6-digit hex
  end

  def relative_luminance(hex)
    r, g, b = hex.scan(/../).map {|c| c.to_i(16) / 255.0 }
    r, g, b = [r, g, b].map {|c| c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055)**2.4 }
    (0.2126 * r) + (0.7152 * g) + (0.0722 * b)
  end

  def contrast_ratio(hex_a, hex_b)
    lighter, darker = [relative_luminance(hex_a), relative_luminance(hex_b)].sort.reverse
    (lighter + 0.05) / (darker + 0.05)
  end

  it 'wires $primary, $link and the sidebar active state to the same accent' do
    expect(variables.fetch('link')).to eq(variables.fetch('primary'))
    expect(variables.fetch('menu-item-active-background-color')).to eq(variables.fetch('primary'))
  end

  it 'keeps the accent green readable as text on a white page background' do
    expect(contrast_ratio(variables.fetch('green'), 'ffffff')).to be >= wcag_aa_normal_text
  end

  it 'keeps white readable on the accent green fill (buttons, badges, active states)' do
    expect(contrast_ratio('ffffff', variables.fetch('green'))).to be >= wcag_aa_normal_text
  end
end
