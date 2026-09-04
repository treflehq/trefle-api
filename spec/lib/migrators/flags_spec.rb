require 'rails_helper'

# `Migrators::Flags.run`/`update_species` read `species.duration` as a raw
# string and write to a `duration_fl` column — both predate the current
# `flag`-typed `duration` bitmask and the `species` table no longer has a
# `duration_fl` column, so those two entry points can't run against today's
# schema. The class methods below are still real, callable logic (they only
# take plain strings/duck-typed objects), so they're covered directly.
RSpec.describe Migrators::Flags do
  describe '.duration_string_to_flags' do
    it 'splits, strips and symbolizes a comma-separated duration string' do
      expect(described_class.duration_string_to_flags('Annual, Perennial')).to eq(%i[annual perennial])
    end

    it 'returns an empty array for a blank value' do
      expect(described_class.duration_string_to_flags(nil)).to eq([])
      expect(described_class.duration_string_to_flags('')).to eq([])
    end
  end

  describe '.string_period_to_months_array' do
    it 'returns an empty array (the nested split never matches the lookup table)' do
      # `period_keys` ends up as an array of arrays (e.g. [["spring"]]), and
      # the table is keyed by plain strings ("spring"), so the lookup always
      # misses. Documented via a real call rather than assumed.
      expect(described_class.string_period_to_months_array('Spring')).to eq([])
      expect(described_class.string_period_to_months_array('Spring and Summer')).to eq([])
    end
  end

  describe '.propagated_by' do
    it 'lists the true propagation methods for a duck-typed record' do
      record = double(
        propagated_by_bare_root: false,
        propagated_by_bulbs: true,
        propagated_by_container: false,
        propagated_by_corms: false,
        propagated_by_cuttings: true,
        propagated_by_seed: true,
        propagated_by_sod: false,
        propagated_by_sprigs: false,
        propagated_by_tubers: false
      )

      expect(described_class.propagated_by(record)).to contain_exactly(:bulbs, :cuttings, :seed)
    end
  end

  describe '.migrate_duration' do
    it 'sets duration_fl from the parsed duration string' do
      record = double(duration: 'Annual, Perennial')
      allow(record).to receive(:duration_fl=)

      described_class.migrate_duration(record)

      expect(record).to have_received(:duration_fl=).with(%i[annual perennial])
    end
  end
end
