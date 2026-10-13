require 'rails_helper'

RSpec.describe Quality::CorrectionActivity do
  let(:species) { Species.friendly.find('abies-alba') }

  def correction(status:, filed:, decided: nil)
    create(:record_correction, record: species, change_status: status).tap do |rc|
      rc.update_columns(created_at: filed, updated_at: decided || filed, decided_at: decided)
    end
  end

  it 'counts filings and decisions per day, and the backlog left at the end of each' do
    baseline = described_class.new(days: 7)
    before = baseline.buckets.index_by(&:starts_on)
    day = 3.days.ago.to_date

    correction(status: :pending, filed: 3.days.ago)
    correction(status: :accepted, filed: 3.days.ago, decided: 3.days.ago)
    correction(status: :rejected, filed: 20.days.ago, decided: 3.days.ago)

    bucket = described_class.new(days: 7).buckets.find {|b| b.starts_on == day }

    expect(bucket.submitted).to eq(before[day].submitted + 2)
    expect(bucket.accepted).to eq(before[day].accepted + 1)
    expect(bucket.rejected).to eq(before[day].rejected + 1)
    # The rejected one was filed before the window: it opens the backlog and
    # leaves it that day; the pending one stays.
    expect(bucket.pending).to eq(before[day].pending + 1)
  end

  it 'groups by week beyond two months' do
    expect(described_class.new(days: 365).period).to eq(:week)
    expect(described_class.new(days: 30).period).to eq(:day)
  end
end
