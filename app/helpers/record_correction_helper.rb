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
    return content_tag(:i, '', class: 'fad fa-exclamation-triangle') if rc.report_source_type? && rc.pending_change_status?

    case rc.change_status
    when 'pending'
      content_tag(:i, '', class: 'fad fa-hourglass-half')
    when 'accepted'
      content_tag(:i, '', class: 'fad fa-check-square')
    when 'rejected'
      content_tag(:i, '', class: 'fad fa-times-square')
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
end
