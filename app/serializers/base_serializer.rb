class BaseSerializer < Panko::Serializer

  # include FastJsonapi::ObjectSerializer
  # cache_options enabled: true, cache_length: 1.week
  attributes :id

  delegate :url_helpers, to: :'Rails.application.routes'

  protected

  # The image row behind `image_url`, with its licence, author and
  # thumbnail, so a client can tell whether it may show the main image
  # without fetching the full species.
  def serialize_main_image(url, species_id: nil)
    image = SpeciesImage.for_url(url, species_id: species_id)
    image && SpeciesImageSerializer.new.serialize(image)
  end

  def render_flag(flag)
    object.send(flag).to_a.empty? ? nil : object.send(flag).to_a
  end
end
