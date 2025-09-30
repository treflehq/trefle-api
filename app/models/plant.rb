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

  validates_uniqueness_of :scientific_name
  validates_uniqueness_of :main_species_id, allow_nil: true

  before_validation :update_completion_ratio!

  def current_completion_percentage
    return 0 unless main_species

    ignored = [
      *main_species.attributes.keys.filter {|e| e.starts_with?('z_leg_') },
      'id', 'inserted_at', 'updated_at', 'created_at', 'complete_data'
    ]

    total = main_species.attributes.without(ignored).keys.count
    complete = main_species.attributes.without(ignored).values.reject {|e| e.nil? || e.blank? || e == 0 }.count

    Rails.logger.debug("[current_completion_percentage] #{complete} complete fields over #{total} fields")
    ((complete.to_f / total.to_f).to_f * 100).to_i # rubocop:todo Style/FloatDivision
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

  def species_species
    species.species_rank
  end

  def subspecies
    species.ssp_rank
  end

  def varieties
    species.var_rank
  end

  def hybrids
    species.subvar_rank
  end

  def forms
    species.form_rank
  end

  def subvarieties
    species.hybrid_rank
  end

end
