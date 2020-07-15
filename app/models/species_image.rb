# == Schema Information
#
# Table name: species_images
#
#  id          :bigint           not null, primary key
#  copyright   :text
#  image_type  :string
#  image_url   :string(255)      not null
#  inserted_at :datetime         not null
#  part        :integer
#  score       :integer          default(0), not null
#  created_at  :datetime
#  updated_at  :datetime         not null
#  species_id  :integer
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

  enum part: {
    flower: 0,
    leaf: 1,
    habit: 2,
    fruit: 3,
    bark: 4,
    other: 5
  }, _suffix: true

end
