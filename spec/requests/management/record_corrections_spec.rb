require 'rails_helper'

RSpec.describe 'Management review queue of corrections', type: :request do
  before { login_as create(:admin), scope: :user }

  let(:species) { Species.friendly.find('abies-alba') }
  let(:queue) { management_record_corrections_path(status: :pending, warning_type: 'Audit::YearDiffers') }

  def correction(**attrs)
    create(:record_correction, { record: species, warning_type: 'Audit::YearDiffers',
                                 correction_json: { year: (species.year || 1900) + 1 }.to_json }.merge(attrs))
  end

  it 'shows the current value next to the proposed one, filtered by check' do
    rc = correction
    other = correction(warning_type: 'Checks::GenusName')

    get queue

    expect(response).to have_http_status(:ok)
    row = Nokogiri::HTML(response.body).at_css("#correction-#{rc.id}")
    expect(row.at_css('.corrections-review__current').text).to eq(species.year.to_s.presence || 'empty')
    expect(row.at_css('.corrections-review__proposed').text).to eq(((species.year || 1900) + 1).to_s)
    expect(response.body).not_to include("correction-#{other.id}")
  end

  it 'flags a correction whose values the record already holds' do
    rc = correction(warning_type: 'Checks::FactDivergence', correction_json: { year: "#{species.year}.0" }.to_json)
    species.update_columns(year: 1768)
    rc.update!(correction_json: { year: '1768.0' }.to_json)

    get management_record_corrections_path(status: :pending)

    row = Nokogiri::HTML(response.body).at_css("#correction-#{rc.id}")
    expect(row.text).to include('Nothing changes')
    expect(row.at_css('input[data-corrections-noop]')).not_to be_nil
  end

  it 'rejects and comes back to the same filtered page' do
    rc = correction

    patch reject_management_record_correction_path(rc), params: { return_to: "#{queue}&page=2" }

    expect(rc.reload).to be_rejected_change_status
    expect(response).to redirect_to("#{queue}&page=2")
  end

  it 'never redirects outside the queue' do
    rc = correction

    patch reject_management_record_correction_path(rc), params: { return_to: 'https://evil.example/' }

    expect(response).to redirect_to(management_record_corrections_path(status: :pending))
  end

  it 'reports a correction the ingester refuses instead of claiming success' do
    rc = correction(record: Genus.first)

    patch accept_management_record_correction_path(rc), params: { return_to: queue }

    expect(rc.reload).to be_pending_change_status
    expect(flash[:alert]).to include('could not be accepted')
  end

  it 'rejects the selected corrections in bulk' do
    first = correction
    second = correction

    patch bulk_management_record_corrections_path, params: { ids: [first.id, second.id], decision: 'reject', return_to: queue }

    expect([first.reload, second.reload]).to all(be_rejected_change_status)
    expect(flash[:notice]).to include('2 correction(s) rejected')
  end

  it 'keeps the comment typed on the row with the decision' do
    rc = correction

    patch accept_management_record_correction_path(rc), params: { comments: { rc.id.to_s => '  WCVP and IPNI agree  ' }, return_to: queue }

    expect(rc.reload).to be_accepted_change_status
    expect(rc.review_comment).to eq('WCVP and IPNI agree')
  end

  it 'applies the selection comment unless a row has its own' do
    first = correction
    second = correction

    patch bulk_management_record_corrections_path,
          params: { ids: [first.id, second.id], decision: 'reject', comment: 'No source', comments: { second.id.to_s => 'Blog source' }, return_to: queue }

    expect(first.reload.review_comment).to eq('No source')
    expect(second.reload.review_comment).to eq('Blog source')
  end

  it 'drops the comment of a decision that did not go through' do
    rc = correction(record: Genus.first)

    patch accept_management_record_correction_path(rc), params: { comments: { rc.id.to_s => 'Looks right' }, return_to: queue }

    expect(rc.reload).to be_pending_change_status
    expect(rc.review_comment).to be_nil
  end

  it 'shows the comment of a decided correction' do
    rc = correction(change_status: :rejected, review_comment: 'Same value, rounded')

    get management_record_corrections_path(status: :rejected)

    expect(Nokogiri::HTML(response.body).at_css("#correction-#{rc.id} .corrections-review__review-comment").text).to eq('Same value, rounded')
  end

  it 'never accepts a deletion in bulk' do
    deletion = correction(change_type: :deletion)

    patch bulk_management_record_corrections_path, params: { ids: [deletion.id], decision: 'accept', return_to: queue }

    expect(deletion.reload).to be_pending_change_status
    expect(Species.exists?(species.id)).to be(true)
    expect(flash[:notice]).to include('1 deletion(s) skipped')
  end
end
