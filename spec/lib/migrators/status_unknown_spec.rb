require 'rails_helper'

RSpec.describe Migrators::StatusUnknown do
  let(:blank) { create(:species) }
  let(:claimed) { create(:species) }
  let(:accepted) { create(:species) }

  before do
    blank.update_columns(status: nil)
    claimed.update_columns(status: nil)
    accepted.update_columns(status: Species.statuses[:accepted])
    SpeciesFact.record!(species: claimed, attribute_name: 'status', source: 'wfo', value: 'accepted')
  end

  it 'sets unknown where nothing is known, and leaves a record with a status fact for a look' do
    result = described_class.run(dry_run: false)

    expect(blank.reload.status).to eq('unknown')
    expect(claimed.reload.status).to be_nil
    expect(accepted.reload.status).to eq('accepted')
    expect(result.to_h).to include(set_unknown: 1, skipped_with_status_fact: 1)
  end

  it 'only counts on a dry run' do
    result = described_class.run(dry_run: true)

    expect(blank.reload.status).to be_nil
    expect(result.set_unknown).to be >= 1
    expect(result.skipped_with_status_fact).to eq(1)
  end
end
