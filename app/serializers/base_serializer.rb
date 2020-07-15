class BaseSerializer < Panko::Serializer

  # include FastJsonapi::ObjectSerializer
  # cache_options enabled: true, cache_length: 1.week
  attributes :id

  delegate :url_helpers, to: :'Rails.application.routes'

  protected

  def render_flag(flag)
    object.send(flag).to_a.empty? ? nil : object.send(flag).to_a
  end
end
