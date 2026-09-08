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
class Plant < ApplicationRecord

  include Filterable
  include Sortable
  include Rangeable

  include Scopes::Plants

  extend FriendlyId
  friendly_id :scientific_name, use: :slugged

  belongs_to :genus, class_name: 'Genus', optional: true
  delegate :family, to: :genus
  delegate :family_id, to: :genus

  belongs_to :main_species, class_name: 'Species', optional: true
  has_many :species, dependent: :destroy
  has_many :foreign_sources_plants, through: :species
  has_many :record_corrections, as: :record, dependent: :destroy

  auto_strip_attributes :author, :common_name, :observations, :bibliography, :author,
                        :family_common_name, :scientific_name, squish: true

  validates :scientific_name, uniqueness: true
  validates :main_species_id, uniqueness: { allow_nil: true }

  before_validation :update_completion_ratio!

  # A plant is as complete as its main species (see Species#current_completion_percentage)
  def current_completion_percentage
    main_species&.current_completion_percentage || 0
  end

  def update_completion_ratio!
    self.completion_ratio = current_completion_percentage
    self.complete_data = (completion_ratio > 25)
  end

  def maintain_metadata!
    self.species_count = species.count
    Plant.reset_counters(id, :species)

    puts "Failed to save: #{errors.messages}" unless save
  end

  # PlantSerializer renders each of the six collections below through
  # SpeciesLightSerializer, which reads `synonyms` and `plant.slug` on top
  # of `genus` for every row: preload all three or /api/v1/plants/:id pays
  # two extra queries per species (see #281).
  def species_species
    species.species_rank.preload(:plant, :genus, :synonyms)
  end

  def subspecies
    species.ssp_rank.preload(:plant, :genus, :synonyms)
  end

  def varieties
    species.var_rank.preload(:plant, :genus, :synonyms)
  end

  def hybrids
    species.hybrid_rank.preload(:plant, :genus, :synonyms)
  end

  def forms
    species.form_rank.preload(:plant, :genus, :synonyms)
  end

  def subvarieties
    species.subvar_rank.preload(:plant, :genus, :synonyms)
  end

end
