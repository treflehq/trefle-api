require 'rails_helper'

RSpec.describe Checks::PlausibleValues do
  let(:species) { Species.friendly.find('abies-alba') }

  it 'does nothing when values are plausible' do
    species.update_columns(average_height_cm: 150, ph_minimum: 5.0, ph_maximum: 7.0)

    expect { described_class.run(species.id) }.not_to change(RecordCorrection, :count)
  end

  it 'flags a value outside its plausible range' do
    species.update_columns(average_height_cm: 999_999)

    expect { described_class.run(species.id) }.to change(RecordCorrection, :count).by(1)

    warning = RecordCorrection.find_by(warning_type: 'Checks::PlausibleValues')
    expect(warning).to be_pending_change_status
    expect(warning.notes).to include('average_height_cm=999999')
  end

  it 'flags inconsistent min/max bounds' do
    species.update_columns(ph_minimum: 8.0, ph_maximum: 5.0)

    expect { described_class.run(species.id) }.to change(RecordCorrection, :count).by(1)

    warning = RecordCorrection.find_by(warning_type: 'Checks::PlausibleValues')
    expect(warning.notes).to include('inconsistent bounds')
  end

  it 'accepting the warning drops the implausible values' do
    species.update_columns(average_height_cm: 999_999)
    described_class.run(species.id)
    warning = RecordCorrection.find_by(warning_type: 'Checks::PlausibleValues')

    described_class.new(species.id).accept!(nil)

    expect(species.reload.average_height_cm).to be_nil
    expect(warning.reload).to be_accepted_change_status
  end

  it 'resolves the warning once the data is fixed' do
    species.update_columns(average_height_cm: 999_999)
    described_class.run(species.id)
    warning = RecordCorrection.find_by(warning_type: 'Checks::PlausibleValues')

    species.update_columns(average_height_cm: 250)
    described_class.run(species.id)

    expect(warning.reload).not_to be_pending_change_status
  end

  it 'names the bound that was violated, not just that one was' do
    species.update_columns(average_height_cm: 999_999)
    described_class.run(species.id)

    warning = RecordCorrection.find_by(warning_type: 'Checks::PlausibleValues')
    expect(warning.notes).to include('outside the plausible range')
    expect(warning.notes).to include('12000')
  end

  it 'names the vocabulary that was violated' do
    species.update_columns(nitrogen_fixation: 'very high')
    described_class.run(species.id)

    warning = RecordCorrection.find_by(warning_type: 'Checks::PlausibleValues')
    expect(warning.notes).to include('outside the allowed vocabulary')
    expect(warning.notes).to include('High')
  end

  it 'drops a value that violates the vocabulary when accepted' do
    species.update_columns(nitrogen_fixation: 'very high')
    described_class.run(species.id)

    described_class.new(species.id).accept!(nil)

    expect(species.reload.nitrogen_fixation).to be_nil
  end
end
