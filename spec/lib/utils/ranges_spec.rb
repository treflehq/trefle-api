require 'rails_helper'

RSpec.describe Utils::Ranges do
  describe '.interval_to_months' do
    it 'returns the months within a same-year interval' do
      expect(described_class.interval_to_months(3, 5)).to eq(%i[mar apr may])
    end

    it 'returns a single month when start and end match' do
      expect(described_class.interval_to_months(1, 1)).to eq(%i[jan])
    end

    it 'wraps around the year end when the interval crosses december' do
      expect(described_class.interval_to_months(11, 2)).to eq(%i[nov dec jan feb])
    end
  end
end
