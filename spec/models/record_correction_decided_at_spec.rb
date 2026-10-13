require 'rails_helper'

RSpec.describe RecordCorrection do
  let(:species) { Species.friendly.find('abies-alba') }

  it 'dates the decision when the status leaves pending, and only then' do
    correction = create(:record_correction, record: species)
    expect(correction.decided_at).to be_nil

    correction.reject!
    decided_at = correction.reload.decided_at
    expect(decided_at).to be_within(5.seconds).of(Time.current)

    correction.update!(notes: 'a later edit')
    expect(correction.reload.decided_at).to eq(decided_at)
  end

  it 'forgets the date when a correction is reopened' do
    correction = create(:record_correction, record: species, change_status: :rejected)

    correction.update!(change_status: :pending)

    expect(correction.reload.decided_at).to be_nil
  end
end
