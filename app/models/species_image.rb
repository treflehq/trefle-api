# == Schema Information
#
# Table name: species_images
#
#  id                     :bigint           not null, primary key
#  author                 :string
#  commercial_use_allowed :boolean
#  copyright              :text
#  image_type             :string
#  image_url              :string(255)      not null
#  inserted_at            :datetime         not null
#  licence                :string
#  licence_url            :string
#  part                   :integer
#  score                  :integer          default(0), not null
#  thumbnail_url          :string
#  created_at             :datetime
#  updated_at             :datetime         not null
#  species_id             :integer
#
# Indexes
#
#  index_species_images_on_species_id         (species_id)
#  species_images_image_url_species_id_index  (image_url,species_id) UNIQUE
#
class SpeciesImage < ApplicationRecord
  belongs_to :species, class_name: 'Species'

  counter_culture %i[species plant], column_name: 'images_count'
  counter_culture [:species], column_name: 'images_count'

  enum :part, {
    flower: 0,
    leaf: 1,
    habit: 2,
    fruit: 3,
    bark: 4,
    other: 5
  }, suffix: true

  # The reuse terms and the thumbnail are read from `copyright` and
  # `image_url` (ImageLicence), whoever writes the row: the Pl@ntNet and
  # POWO crawlers, the management form, a merge. They follow the copyright
  # when it changes and are never set on their own.
  before_save :derive_licence, if: -> { new_record? || will_save_change_to_copyright? || will_save_change_to_image_url? }

  # The image row behind a species' or plant's `main_image_url`, to expose
  # its reuse terms next to the URL. The same URL carries the same copyright
  # on every species that holds it, so the species is only a preference.
  def self.for_url(url, species_id: nil)
    return nil if url.blank?

    (species_id && find_by(image_url: url, species_id: species_id)) || where(image_url: url).order(:id).first
  end

  def derive_licence
    assign_attributes(ImageLicence.derive(copyright: copyright, image_url: image_url))
  end

  def as_main_image!
    species.main_image_url = image_url if image_url
    species.save
  end
end
