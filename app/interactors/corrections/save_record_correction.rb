class Corrections::SaveRecordCorrection
  include Interactor

  def call
    context.record_correction = ::RecordCorrection.new(record_correction_params)

    context.fail!(messages: context.record_correction.errors.messages) unless context.record_correction.save
  end

  private

  def record_correction_params
    {
      record: context.record,
      user: context.user,
      correction_json: context.correction.to_json,
      notes: context.notes,
      change_type: context.change_type,
      source_type: context.source_type,
      change_notes: context.change_notes,
      source_reference: context.source_reference
    }.compact
  end

end
