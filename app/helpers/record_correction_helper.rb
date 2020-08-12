module RecordCorrectionHelper
  def title_for_correction(rc)
    limit = 2
    correction = rc.correction_json ? JSON.parse(rc.correction_json) : {}

    title = "#{rc.change_type.to_s.humanize}"

    if correction.any?
      changes = correction.keys.first(limit)
      remaining = correction.keys.count - limit
      sentence = [*changes, (remaining > 0 ? "#{remaining} other fields" : nil)].compact.to_sentence
      title = "#{title} on #{sentence}"
    end
    title
  end
end
