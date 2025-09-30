class Corrections::SaveRecordCorrection
  include Interactor

  def call
    context.record_correction = ::RecordCorrection.where(finder_params).first

    puts "Looking for RC: #{finder_params.inspect}"
    puts "=> Got: #{context.record_correction.inspect}"

    if context.record_correction
      context.record_correction.assign_attributes(record_correction_params)
      puts "Updates: #{context.record_correction.inspect}"
    else
      context.record_correction = ::RecordCorrection.new(record_correction_params)
      puts "Creates: #{context.record_correction.inspect}"
    end
    puts "Before saving: #{context.record_correction.inspect}"

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

  def finder_params
    {
      record_id: context.record&.id,
      record_type: context.record&.class&.to_s,
      user_id: context.user&.id,
      # change_type: context.change_type,
      change_status: :pending
    }
  end

end
