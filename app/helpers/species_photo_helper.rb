# Renders species photos as real <img> tags (lazy, sized, with alt text) instead of
# the CSS background-image divs the explore views used to rely on, and supplies a
# tinted placeholder for species that have no photo at all. See issue #232.
module SpeciesPhotoHelper
  PLANTNET_ORIGINAL_SEGMENT = '/image/o/'.freeze

  DEFAULT_WIDTH = 400
  DEFAULT_HEIGHT = 300

  # Swaps a plantnet original-size URL (bs.plantnet.org/image/o/...) for the given
  # size variant (plantnet supports o/m/s). Non-plantnet URLs (legacy cloudfront
  # ones, for instance) are returned untouched, since we don't know their variants.
  def species_photo_src(url, size: :m)
    return url if url.blank?

    url.sub(PLANTNET_ORIGINAL_SEGMENT, "/image/#{size}/")
  end

  def species_photo_alt(species)
    return '' unless species

    if species.common_name.present?
      "#{species.scientific_name} (#{species.common_name})"
    else
      species.scientific_name.to_s
    end
  end

  # Renders a lazy-loaded, medium-sized <img> for the species' main photo, or a
  # tinted placeholder with a leaf glyph when the species has no photo.
  def species_photo_tag(species, css_class:, size: :m, width: DEFAULT_WIDTH, height: DEFAULT_HEIGHT)
    url = species&.main_image_url

    if url.present?
      image_tag species_photo_src(url, size: size),
                class: css_class,
                alt: species_photo_alt(species),
                loading: 'lazy',
                decoding: 'async',
                width: width,
                height: height
    else
      content_tag :div, class: "#{css_class} #{css_class}--empty" do
        fa_icon('leaf')
      end
    end
  end
end
