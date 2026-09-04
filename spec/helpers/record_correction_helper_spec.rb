require 'rails_helper'

RSpec.describe RecordCorrectionHelper, type: :helper do
  let(:record_correction) { create(:record_correction) }

  describe '#title_for_correction' do
    it 'lists the changed fields when there is a correction payload' do
      record_correction.update!(correction_json: { common_name: 'Silver fir', author: 'Mill.' }.to_json)

      expect(helper.title_for_correction(record_correction)).to eq('Update on common_name and author')
    end

    it 'summarizes fields beyond the limit as "N other fields"' do
      record_correction.update!(
        correction_json: { a: 1, b: 2, c: 3, d: 4 }.to_json
      )

      expect(helper.title_for_correction(record_correction)).to eq('Update on a, b, and 2 other fields')
    end
  end

  describe '#class_for_correction_status' do
    it 'maps accepted to the success tag class' do
      expect(helper.class_for_correction_status(:accepted)).to eq('tag is-success')
    end

    it 'maps rejected to the danger tag class' do
      expect(helper.class_for_correction_status(:rejected)).to eq('tag is-danger')
    end
  end

  describe '#badge_for_correction_status' do
    it 'shows a check icon once accepted' do
      record_correction.update!(change_status: :accepted)

      expect(helper.badge_for_correction_status(record_correction)).to include('check-square')
    end

    it 'shows a times icon once rejected' do
      record_correction.update!(change_status: :rejected)

      expect(helper.badge_for_correction_status(record_correction)).to include('times-square')
    end
  end

  describe '#pretty_changes' do
    it 'pretty-prints the change notes JSON' do
      record_correction.update!(change_notes: { name: %w[old new] }.to_json)

      expect(helper.pretty_changes(record_correction)).to include('"name"')
    end

    it 'is blank when there are no change notes' do
      record_correction.update!(change_notes: nil)

      expect(helper.pretty_changes(record_correction)).to eq('')
    end
  end

  describe '#status_sentence' do
    it 'reads as accepted and merged' do
      record_correction.update!(change_status: :accepted)

      expect(helper.status_sentence(record_correction)).to eq('Correction has been accepted and merged in the database.')
    end

    it 'reads as rejected' do
      record_correction.update!(change_status: :rejected)

      expect(helper.status_sentence(record_correction)).to eq('Correction has been rejected.')
    end
  end

  describe '#source_sentence' do
    it 'describes a living-specimen observation' do
      record_correction.update!(source_type: :observation)

      expect(helper.source_sentence(record_correction)).to include('observation of a living specimen')
    end

    it 'links out to each external source reference' do
      record_correction.update!(source_type: :external, source_reference: 'http://a.example.com,http://b.example.com')

      rendered = helper.source_sentence(record_correction)

      expect(rendered).to include('http://a.example.com')
      expect(rendered).to include('http://b.example.com')
    end

    it 'falls back to a plain "Source: <type>" sentence' do
      record_correction.update!(source_type: :report)

      expect(helper.source_sentence(record_correction)).to eq('Source: report')
    end
  end
end
