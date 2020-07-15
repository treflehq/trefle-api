class Corrections::ValidateRecordCorrection
  include Interactor

  def call
    check_params!

    context.correction = JSON.parse(context.correction) if context.correction.is_a?(String)
    context.correction['scientific_name'] ||= context.record.scientific_name

    check_properties!
    check_schema!
    check_ingestion!
  end

  private

  def check_properties!
    allowed_keys = Schemas::V1::RecordCorrection.correction_body[:properties].keys.map(&:to_sym)
    change_keys = context.correction.keys.map(&:to_sym)
    diff = change_keys - allowed_keys

    context.fail!(messages: "Unknown attributes: #{diff.to_sentence}") if diff.any?
  end

  # Validate schema
  def check_schema!
    validation = JSON::Validator.fully_validate(
      Schemas::V1::RecordCorrection.correction_body,
      context.correction
    )
    puts 'Validation !'
    pp validation
    context.fail!(messages: validation) if validation.any?
  end

  # Validate ingester
  def check_ingestion!
    context.ingester = Ingester::Species.new(context.correction, dry_run: true)
    result = context.ingester.ingest!
    context.fail!(messages: result[:errors]) if result[:errors].any?
    context.fail!(messages: 'This correction don\'t seems to change anything') if result[:changes].empty?
    context.change_notes = result[:changes].to_json
  rescue Ingester::IngesterException => e
    context.fail!(messages: e)
  end

  def check_params!
    context.fail!(messages: 'Unable to find associated record') if context.record.nil?
    context.fail!(messages: 'No correction has been submitted') if context.correction.blank?
    context.fail!(messages: 'No user for correction') if context.user.nil?
    context.fail!(messages: "Corrections on #{context.record.class} are not supported yet") unless context.record.is_a?(Species)
  end

end
