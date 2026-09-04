require 'rails_helper'

RSpec.describe PlantsHelper, type: :helper do
  describe '#completion_percentage' do
    # The denominator excludes id/inserted_at/updated_at, but the numerator
    # (`values.reject(&:nil?)`) doesn't apply the same exclusion — so those
    # three always-present metadata fields count toward "complete" without
    # counting toward the total, and the result can exceed 100%. Unused
    # elsewhere in the app (superseded by Species#current_completion_percentage);
    # pinning the real behavior rather than the presumably intended one.
    it 'counts every non-nil attribute, including the excluded metadata keys, against the reduced total' do
      record = double(attributes: {
        'id' => 1,
        'inserted_at' => Time.zone.now,
        'updated_at' => Time.zone.now,
        'scientific_name' => 'Abies alba',
        'common_name' => nil
      })

      expect(helper.completion_percentage(record)).to eq(200)
    end

    it 'is 0 only when every attribute, metadata included, is nil' do
      record = double(attributes: {
        'id' => nil,
        'inserted_at' => nil,
        'updated_at' => nil,
        'scientific_name' => nil,
        'common_name' => nil
      })

      expect(helper.completion_percentage(record)).to eq(0)
    end
  end
end
