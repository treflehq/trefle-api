require 'rails_helper'

# The ecological indicators have one definition of their classes,
# config/ecological_indicators.yml; the plausible ranges the ingester and
# Checks::PlausibleValues enforce must not drift from it (a 0-10 range once
# refused the soil humidity classes 11 and 12).
RSpec.describe 'Ecological indicator ranges' do
  indicators = YAML.load_file(Rails.root.join('config/ecological_indicators.yml'))['indicators']

  indicators.each do |name, definition|
    it "uses the #{name} classes as its plausible range" do
      expect(Traits.field(name)['plausible_range']).to eq([definition['min'], definition['max']])
    end
  end

  it 'accepts the submerged soil humidity class' do
    expect(Traits.plausible?('ground_humidity', 12)).to be(true)
  end
end
