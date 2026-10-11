module RecordCorrectionHelper
  def title_for_correction(rc)
    limit = 2
    correction = rc.correction_json ? JSON.parse(rc.correction_json) : {}

    title = rc.report_source_type? ? 'Report' : rc.change_type.to_s.humanize.to_s

    if correction.any?
      changes = correction.keys.first(limit)
      remaining = correction.keys.count - limit
      sentence = [*changes, (remaining > 0 ? "#{remaining} other fields" : nil)].compact.to_sentence
      title = "#{title} on #{sentence}"
    end
    title
  end

  def class_for_correction_status(status)
    case status.to_sym
    when :pending
      'tag is-info'
    when :accepted
      'tag is-success'
    when :rejected
      'tag is-danger'
    end
  end

  def badge_for_correction_status(rc)
    return fa_icon('exclamation-triangle') if rc.report_source_type? && rc.pending_change_status?

    case rc.change_status
    when 'pending'
      fa_icon('hourglass-half')
    when 'accepted'
      fa_icon('check-square')
    when 'rejected'
      fa_icon('times-square')
    end
  end

  def pretty_correction(rc)
    rc.correction_json.blank? ? '' : JSON.pretty_generate(JSON.parse(rc.correction_json))
  end

  def pretty_changes(rc)
    rc.change_notes.blank? ? '' : JSON.pretty_generate(JSON.parse(rc.change_notes))
  end

  def status_sentence(rc)
    name = rc.report_source_type? ? 'Report' : 'Correction'
    case rc.change_status
    when 'pending'
      "#{name} is pending validation."
    when 'accepted'
      "#{name} has been accepted and merged in the database."
    when 'rejected'
      "#{name} has been rejected."
    end
  end

  def source_sentence(rc)
    if rc.observation_source_type?
      content_tag(:p, 'The source of the correction is an observation of a living specimen.')
    elsif rc.external_source_type?
      content_tag(:div) do
        content_tag(:p, 'The source of the correction is from an external source(s):') +
          content_tag(:ul) do
            rc.source_reference&.split(',')&.map do |ref|
              concat(content_tag(:li) { link_to(ref, ref) })
            end
          end
      end
    else
      "Source: #{rc.source_type}"
    end
  end

  # [field, current value, proposed value, changed?] for each field of the
  # correction; current is :none when the field is not a column of the
  # record (unit helpers such as average_height_unit).
  def correction_field_changes(rc)
    proposed = begin
      JSON.parse(rc.correction_json.presence || '{}')
    rescue JSON::ParserError
      {}
    end
    return [] unless proposed.is_a?(Hash)

    proposed.map do |field, value|
      current = rc.record&.has_attribute?(field) ? rc.record[field] : :none
      [field, current, value, current == :none || !same_correction_value?(current, value)]
    end
  end

  # "1600" and 1600.0 are the same height: numbers compare as numbers.
  def same_correction_value?(current, proposed)
    return current.to_s == proposed.to_s unless [current, proposed].all? {|v| v.is_a?(Numeric) || v.to_s.match?(/\A-?\d+(\.\d+)?\z/) }

    BigDecimal(current.to_s) == BigDecimal(proposed.to_s)
  end

  def correction_value(value)
    return tag.span('n/a', class: 'has-text-grey-light') if value == :none
    return tag.em('empty', class: 'has-text-grey') if value.nil? || value == ''

    Array(value).join(', ')
  end

  # The check that filed the correction, without its namespace.
  def correction_kind(rc)
    return 'Community' if rc.warning_type.blank?

    rc.warning_type.to_s.split('::').last.underscore.humanize
  end
end
