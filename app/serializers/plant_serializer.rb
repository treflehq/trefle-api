# == Schema Information
#
# Table name: plants
#
#  id                      :bigint           not null, primary key
#  author                  :string(255)
#  bibliography            :text
#  common_name             :string(255)
#  complete_data           :boolean
#  completion_ratio        :integer
#  family_common_name      :string(255)
#  images_count            :integer          default(0), not null
#  inserted_at             :datetime         not null
#  main_image_url          :string
#  main_species_gbif_score :integer          default(0), not null
#  observations            :text
#  reviewed_at             :datetime
#  scientific_name         :string(255)
#  slug                    :string(255)
#  sources_count           :integer          default(0), not null
#  species_count           :integer
#  status                  :string(255)
#  vegetable               :boolean          default(FALSE), not null
#  year                    :integer
#  created_at              :datetime
#  updated_at              :datetime         not null
#  genus_id                :bigint
#  main_species_id         :integer
#
# Indexes
#
#  index_plants_on_slug                (slug)
#  plants_genus_id_index               (genus_id)
#  plants_id_main_species_id_index     (id,main_species_id) UNIQUE
#  plants_main_species_gbif_score_idx  (main_species_gbif_score)
#  plants_main_species_id_index        (main_species_id)
#  plants_scientific_name_index        (scientific_name) UNIQUE
#
# Foreign Keys
#
#  plants_genus_id_fkey  (genus_id => genuses.id)
#

class PlantSerializer < BaseSerializer

  attributes :common_name, :slug, :scientific_name,
             :year, :bibliography, :author, #:status,
             :family_common_name, :genus_id,
             :main_species_id, :vegetable,
             :observations,
             :links, :image_url

  has_one :main_species, serializer: SpeciesSerializer
  has_many :species_species, serializer: SpeciesLightSerializer, name: :species
  has_many :subspecies, serializer: SpeciesLightSerializer
  has_many :varieties, serializer: SpeciesLightSerializer
  has_many :hybrids, serializer: SpeciesLightSerializer
  has_many :forms, serializer: SpeciesLightSerializer
  has_many :subvarieties, serializer: SpeciesLightSerializer

  has_many :foreign_sources_plants, serializer: ForeignSourcesPlantSerializer, name: :sources

  has_one :genus, serializer: GenusLightSerializer
  has_one :family, serializer: FamilyLightSerializer

  def image_url
    object.main_species&.main_image_url
  end

  def year
    object.main_species&.year
  end

  def bibliography
    object.main_species&.bibliography
  end

  def author
    object.main_species&.author
  end

  def family_common_name
    object.main_species&.family_common_name
  end

  def genus_id
    object.main_species&.genus_id
  end

  def observations
    object.main_species&.observations
  end

  def vegetable
    object.main_species&.vegetable
  end

  def links
    {
      self: url_helpers.api_v1_plant_path(object),
      species: url_helpers.api_v1_plant_species_index_path(object),
      genus: url_helpers.api_v1_genus_path(object.genus.slug)
    }
  end
end
