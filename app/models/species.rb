# == Schema Information
#
# Table name: species
#
#  id                                 :bigint           not null, primary key
#  adapted_to_coarse_textured_soils   :boolean
#  adapted_to_fine_textured_soils     :boolean
#  adapted_to_medium_textured_soils   :boolean
#  anaerobic_tolerance                :string(255)
#  atmospheric_humidity               :integer
#  author                             :string(255)
#  average_height_cm                  :integer
#  bibliography                       :text
#  biological_type                    :integer
#  biological_type_raw                :string
#  bloom_months                       :bigint           default(0), not null
#  c_n_ratio                          :string(255)
#  caco_3_tolerance                   :string(255)
#  checked_at                         :datetime
#  common_name                        :string(255)
#  complete_data                      :boolean
#  dissemination                      :integer          default(0), not null
#  dissemination_raw                  :string
#  duration                           :bigint           default(0), not null
#  edible                             :boolean
#  edible_part                        :integer          default(0), not null
#  family_common_name                 :string(255)
#  family_name                        :string
#  flower_color                       :bigint           default(0), not null
#  flower_conspicuous                 :boolean
#  foliage_color                      :bigint           default(0), not null
#  foliage_texture                    :integer
#  frost_free_days_minimum            :float
#  fruit_color                        :bigint           default(0), not null
#  fruit_conspicuous                  :boolean
#  fruit_months                       :bigint           default(0), not null
#  fruit_seed_persistence             :boolean
#  fruit_shape                        :integer
#  fruit_shape_raw                    :string
#  full_token                         :text
#  gbif_score                         :integer          default(0), not null
#  genus_name                         :string
#  ground_humidity                    :integer
#  growth_form                        :string(255)
#  growth_habit                       :string(255)
#  growth_months                      :bigint           default(0), not null
#  growth_rate                        :string(255)
#  hardiness_zone                     :integer
#  images_count                       :integer          default(0), not null
#  inflorescence_form                 :integer
#  inflorescence_raw                  :string
#  inflorescence_type                 :integer
#  inserted_at                        :datetime         not null
#  known_allelopath                   :boolean
#  leaf_retention                     :boolean
#  lifespan                           :string(255)
#  light                              :integer
#  ligneous_type                      :integer
#  main_image_url                     :string
#  maturation_order                   :string
#  maturation_order_raw               :string
#  maximum_height_cm                  :integer
#  maximum_height_unit                :string(12)
#  maximum_height_value               :decimal(, )
#  maximum_precipitation_mm           :integer
#  maximum_temperature_deg_c          :decimal(, )
#  maximum_temperature_deg_f          :decimal(, )
#  minimum_precipitation_mm           :integer
#  minimum_root_depth_cm              :integer
#  minimum_temperature_deg_c          :decimal(, )
#  minimum_temperature_deg_f          :decimal(, )
#  nitrogen_fixation                  :string(255)
#  observations                       :text
#  ph_maximum                         :float
#  ph_minimum                         :float
#  planting_days_to_harvest           :integer
#  planting_description               :text
#  planting_row_spacing_cm            :integer
#  planting_sowing_description        :text
#  planting_spread_cm                 :integer
#  pollinisation                      :integer          default(0), not null
#  pollinisation_raw                  :string
#  propagated_by                      :bigint           default(0), not null
#  protein_potential                  :string(255)
#  rank                               :integer
#  reviewed_at                        :datetime
#  scientific_name                    :string(255)
#  sexuality                          :integer          default(0), not null
#  sexuality_raw                      :string
#  shape_and_orientation              :string(255)
#  slug                               :string(255)
#  soil_nutriments                    :integer
#  soil_salinity                      :integer
#  soil_texture                       :integer
#  sources_count                      :integer          default(0), not null
#  status                             :integer
#  synonyms_count                     :integer          default(0), not null
#  token                              :text
#  toxicity                           :integer
#  vegetable                          :boolean
#  year                               :integer
#  z_leg_after_harvest_regrowth_rate  :string(255)
#  z_leg_berry_nut_seed_product       :boolean
#  z_leg_bloat                        :string(255)
#  z_leg_christmas_tree_product       :boolean
#  z_leg_cold_stratification_required :boolean
#  z_leg_commercial_availability      :string(255)
#  z_leg_coppice_potential            :boolean
#  z_leg_drought_tolerance            :string(255)
#  z_leg_fall_conspicuous             :boolean
#  z_leg_fertility_requirement        :string(255)
#  z_leg_fire_resistance              :boolean
#  z_leg_fire_tolerance               :string(255)
#  z_leg_fodder_product               :boolean
#  z_leg_foliage_porosity_summer      :string(255)
#  z_leg_foliage_porosity_winter      :string(255)
#  z_leg_fruit_seed_abundance         :string(255)
#  z_leg_fuelwood_product             :string(255)
#  z_leg_hedge_tolerance              :string(255)
#  z_leg_low_growing_grass            :boolean
#  z_leg_lumber_product               :boolean
#  z_leg_moisture_use                 :string(255)
#  z_leg_native_status                :string(255)
#  z_leg_naval_store_product          :boolean
#  z_leg_nursery_stock_product        :boolean
#  z_leg_palatable_browse_animal      :string(255)
#  z_leg_palatable_graze_animal       :string(255)
#  z_leg_palatable_human              :boolean
#  z_leg_post_product                 :boolean
#  z_leg_pulpwood_product             :boolean
#  z_leg_resprout_ability             :boolean
#  z_leg_salinity_tolerance           :string(255)
#  z_leg_seed_spread_rate             :string(255)
#  z_leg_seedling_vigor               :string(255)
#  z_leg_seeds_per_pound              :float
#  z_leg_shade_tolerance              :string(255)
#  z_leg_small_grain                  :boolean
#  z_leg_usda_name                    :string(255)
#  z_leg_usda_synonym                 :string(255)
#  z_leg_vegetative_spread_rate       :string(255)
#  z_leg_veneer_product               :boolean
#  created_at                         :datetime
#  updated_at                         :datetime         not null
#  genus_id                           :integer
#  main_species_id                    :integer
#  plant_id                           :bigint
#
# Indexes
#
#  index_species_on_average_height_cm         (average_height_cm)
#  index_species_on_family_common_name        (family_common_name)
#  index_species_on_flower_conspicuous        (flower_conspicuous)
#  index_species_on_minimum_precipitation_mm  (minimum_precipitation_mm)
#  index_species_on_minimum_root_depth_cm     (minimum_root_depth_cm)
#  index_species_on_planting_row_spacing_cm   (planting_row_spacing_cm)
#  index_species_on_planting_spread_cm        (planting_spread_cm)
#  index_species_on_slug                      (slug)
#  index_species_on_token                     (token)
#  species_gbif_score_idx                     (gbif_score)
#  species_genus_id_index                     (genus_id)
#  species_main_species_id_index              (main_species_id)
#  species_plant_id_index                     (plant_id)
#  species_scientific_name_index              (scientific_name) UNIQUE
#
# Foreign Keys
#
#  species_plant_id_fkey  (plant_id => plants.id)
#
class Species < ApplicationRecord # rubocop:todo Metrics/ClassLength
  include ActiveModel::Validations

  PLANTS_ATTRIBUTES = %w[
    year bibliography author common_name family_common_name
    genus_id vegetable observations main_image_url reviewed_at
  ].freeze

  STRING_ATTRIBUTES = %I[
    anaerobic_tolerance
    author
    c_n_ratio
    caco_3_tolerance
    common_name
    dissemination
    family_common_name
    fruit_shape
    growth_form
    growth_habit
    growth_rate
    lifespan
    maturation_order
    nitrogen_fixation
    pollinisation
    protein_potential
    sexuality
    shape_and_orientation
  ].freeze

  include Filterable
  include Sortable
  include Rangeable

  include Scopes::Species

  belongs_to :plant, optional: true
  belongs_to :genus
  belongs_to :main_species, class_name: 'Species', optional: true
  belongs_to :synonym_of, class_name: 'Species', optional: true
  has_many :old_synonyms, class_name: 'Species', foreign_key: :synonym_of_id
  has_many :species_images, dependent: :destroy
  has_many :foreign_sources_plants, as: :record, dependent: :destroy, inverse_of: :record
  has_many :foreign_sources, through: :foreign_sources_plants
  has_many :record_corrections, as: :record, dependent: :destroy
  has_many :synonyms, as: :record, dependent: :destroy
  has_many :common_names, as: :record, dependent: :destroy

  has_many :species_distributions, dependent: :destroy
  has_many :zones, through: :species_distributions

  accepts_nested_attributes_for :common_names
  accepts_nested_attributes_for :species_distributions
  accepts_nested_attributes_for :synonyms
  accepts_nested_attributes_for :foreign_sources_plants
  accepts_nested_attributes_for :species_images

  counter_culture :plant

  # measured_length :average_height
  # validates :average_height, measured: { units: %I[in ft cm m] }

  # measured_length :maximum_height
  # validates :maximum_height, measured: { units: %I[in ft cm m] }

  # measured_length :minimum_root_depth
  # validates :minimum_root_depth, measured: { units: %I[in ft cm m] }

  # measured_length :minimum_precipitation
  # validates :minimum_precipitation, measured: { units: %I[in ft mm cm m] }

  # measured_length :maximum_precipitation
  # validates :maximum_precipitation, measured: { units: %I[in ft cm m] }

  # measured Measured::Area, :minimum_planting_density, measured: { units: %I[ac m2] }

  # (700 / Measured::Area.new(1, 'acres').convert_to('acre').value).to_f => 700.0
  # (700 / Measured::Area.new(1, 'm2').convert_to('acre').value).to_f => 2832802.0

  # Check the scientific name is well formatted according to rank
  validates :scientific_name,
            scientific_name_length: true,
            scientific_name_structure: true

  enum rank: {
    species: 0,
    ssp: 1,
    var: 2,
    form: 3,
    hybrid: 4,
    subvar: 5
  }, _suffix: true

  enum status: {
    accepted: 0,
    unknown: 1,
    rejected: 2,
    doubtful: 3
  }, _suffix: true

  enum toxicity: {
    none: 0,
    low: 1,
    medium: 2,
    high: 3
  }, _suffix: true

  enum foliage_texture: {
    fine: 0,
    medium: 1,
    coarse: 2
  }, _suffix: true

  enum ligneous_type: {
    liana: 0,
    subshrub: 1,
    shrub: 2,
    tree: 3,
    parasite: 4
  }, _suffix: true

  enum soil_texture: {
    'argile' => 1,
    'intermediaire' => 2,
    'limon' => 3,
    'sable_fin' => 4,
    'sable_grossier' => 5,
    'graviers' => 6,
    'galets' => 7,
    'blocs_fentes_des_parois' => 8,
    'dalle' => 9
  }, _suffix: true

  flag :duration, %i[annual biennial perennial]

  # @TODO DEPRECATED / Not used
  flag :propagated_by, %i[bare_root bulbs container corms cuttings seed sod sprigs tubers]
  flag :growth_months,  %i[jan feb mar apr may jun jul aug sep oct nov dec]
  flag :bloom_months,   %i[jan feb mar apr may jun jul aug sep oct nov dec]
  flag :fruit_months,   %i[jan feb mar apr may jun jul aug sep oct nov dec]

  # white -> #ffffff
  # red -> #e6194B
  # brown -> #9A6324
  # orange -> #f58231
  # yellow -> #ffe119
  # lime -> #bfef45
  # green -> #3cb44b
  # cyan -> #42d4f4
  # blue -> #4363d8
  # purple -> #911eb4
  # magenta -> #f032e6
  # grey -> #a9a9a9
  # black -> #000000
  flag :flower_color, %i[white red brown orange yellow lime green cyan blue purple magenta grey black]
  flag :fruit_color, %i[white red brown orange yellow lime green cyan blue purple magenta grey black]
  flag :foliage_color, %i[white red brown orange yellow lime green cyan blue purple magenta grey black]

  flag :edible_part, %i[roots stem leaves flowers fruits seeds]

  before_validation :infer_rank
  before_validation :infer_genus
  before_validation :complete_cache_fields

  before_create :infer_plant

  before_save :regenerate_tokens!

  extend FriendlyId
  friendly_id :scientific_name, use: :slugged

  after_save :setup_main_species
  after_save :reindex
  after_destroy :deindex

  auto_strip_attributes(*STRING_ATTRIBUTES, squish: true)

  validates_uniqueness_of :scientific_name
  # rubocop:todo Style/FormatStringToken
  validates_uniqueness_of :token, allow_nil: true, message: 'A species with a close scientific name is already registered (token=%{value})'
  # rubocop:enable Style/FormatStringToken

  # Will worward his data to the plant
  def setup_main_species
    return unless main_species.nil? || main_species.id == id

    plant.update_columns(merge_plant_over_species.merge(main_species_gbif_score: gbif_score))
  end

  def reindex
    ::Search::ReindexSpeciesWorker.perform_async(id)
  end

  def deindex
    ::Search::DeindexSpeciesWorker.perform_async(id)
  end

  def complete_cache_fields
    self.genus_name = genus&.name
    self.family_name = genus&.family&.name
    return unless main_image_url.nil?

    candidate = species_images.order(score: :desc).where(part: :habit)&.first&.image_url
    candidate ||= species_images.order(score: :desc)&.first&.image_url
    self.main_image_url = candidate if candidate
  end

  # Theses are tokens used for integrity and search
  def regenerate_tokens!
    # This one is for integrity, to avoir same species with similar names
    self.token = scientific_name.parameterize.split('-').join(' ').strip

    # We tokenize the english common names (Ex: Strawberry)
    names_tokens = common_names
      .where(lang: 'en')
      .pluck(:name)
      .map {|e| e.parameterize.split('-') }
      .flatten
      .uniq

    # We tokenize the synonyms
    syn_tokens = synonyms
      .pluck(:name)
      .map {|e| e.parameterize.split('-') }
      .flatten
      .uniq

    # This one is for search, with the known common names & synonyms
    self.full_token = [
      token,
      *names_tokens,
      *syn_tokens
    ].join(' ').strip
  end

  def infer_genus
    return if genus_id

    self.genus_id ||= main_species.genus_id if main_species
    self.genus_id ||= Genus.find_by_name(scientific_name.split(' ').first)&.id
  end

  def infer_plant
    return if plant_id

    self.plant_id ||= main_species.plant_id if main_species

    return if plant_id

    return unless genus

    self.plant_id = Plant.where(scientific_name: root_name, genus: genus).first_or_create!(
      attributes.slice(*PLANTS_ATTRIBUTES).compact
    )&.id
  end

  # @TODO Not sure, we disable that for now
  def inherit_from_plant
    return unless plant

    assign_attributes(merge_species_over_plant)
  end

  def inherit_complete_data_from_species(from)
    puts "Merging data of #{from.scientific_name} into #{scientific_name}"
    assign_attributes(merge_from_complete_data(from))
    save
  end

  def infer_rank
    return unless rank.nil?

    self.rank = 'species' if main_species_id.nil? && has_root_name?
  end

  def merge_plant_over_species
    merge_attrs = PLANTS_ATTRIBUTES

    pattrs = plant.reload ? plant.reload.attributes.slice(*merge_attrs).compact : {}
    attributes.slice(*merge_attrs).compact.merge(pattrs)
  end

  def merge_species_over_plant
    merge_attrs = PLANTS_ATTRIBUTES
    pattrs = plant.reload ? plant.reload.attributes.slice(*merge_attrs).compact : {}
    pattrs.merge(attributes.slice(*merge_attrs).compact)
  end

  def merge_from_complete_data(species_from) # rubocop:todo Metrics/MethodLength
    merge_attrs = %w[
      adapted_to_coarse_textured_soils
      adapted_to_fine_textured_soils
      adapted_to_medium_textured_soils
      anaerobic_tolerance
      atmospheric_humidity
      author
      bibliography
      biological_type
      biological_type_raw
      bloom_months
      c_n_ratio
      caco_3_tolerance
      common_name
      complete_data
      dissemination
      dissemination_raw
      duration
      edible
      family_common_name
      flower_color
      flower_conspicuous
      foliage_color
      foliage_texture
      frost_free_days_minimum
      fruit_color
      fruit_conspicuous
      fruit_months
      fruit_seed_persistence
      fruit_shape
      fruit_shape_raw
      gbif_score
      ground_humidity
      growth_form
      growth_habit
      growth_months
      growth_rate
      hardiness_zone
      images_count
      inflorescence_form
      inflorescence_raw
      inflorescence_type
      inserted_at
      known_allelopath
      leaf_retention
      lifespan
      light
      ligneous_type
      maturation_order
      maturation_order_raw
      maximum_temperature_deg_c
      maximum_temperature_deg_f
      minimum_temperature_deg_c
      minimum_temperature_deg_f
      nitrogen_fixation
      observations
      ph_maximum
      ph_minimum
      pollinisation
      pollinisation_raw
      propagated_by
      protein_potential
      rank
      reviewed_at
      scientific_name
      sexuality
      sexuality_raw
      shape_and_orientation
      slug
      soil_nutriments
      soil_salinity
      soil_texture
      sources_count
      status
      synonyms_count
      toxicity
      vegetable
      year
      z_leg_after_harvest_regrowth_rate
      z_leg_berry_nut_seed_product
      z_leg_bloat
      z_leg_christmas_tree_product
      z_leg_cold_stratification_required
      z_leg_commercial_availability
      z_leg_coppice_potential
      z_leg_drought_tolerance
      z_leg_fall_conspicuous
      z_leg_fertility_requirement
      z_leg_fire_resistance
      z_leg_fire_tolerance
      z_leg_fodder_product
      z_leg_foliage_porosity_summer
      z_leg_foliage_porosity_winter
      z_leg_fruit_seed_abundance
      z_leg_fuelwood_product
      z_leg_hedge_tolerance
      z_leg_low_growing_grass
      z_leg_lumber_product
      z_leg_moisture_use
      z_leg_native_status
      z_leg_naval_store_product
      z_leg_nursery_stock_product
      z_leg_palatable_browse_animal
      z_leg_palatable_graze_animal
      z_leg_palatable_human
      z_leg_post_product
      z_leg_pulpwood_product
      z_leg_resprout_ability
      z_leg_salinity_tolerance
      z_leg_seed_spread_rate
      z_leg_seedling_vigor
      z_leg_seeds_per_pound
      z_leg_shade_tolerance
      z_leg_small_grain
      z_leg_usda_name
      z_leg_usda_synonym
      z_leg_vegetative_spread_rate
      z_leg_veneer_product
    ]

    theirs = species_from ? species_from.attributes.slice(*merge_attrs).compact : {}
    ours = attributes.slice(*merge_attrs).compact
    theirs.merge(ours)
  end

  def has_root_name? # rubocop:todo Naming/PredicateName
    root_name == scientific_name
  end

  def root_name
    Species.root_scientific_name(scientific_name)
  end

  def self.root_scientific_name(full)
    full.gsub(/\s+(var|ssp|subvar|x|(fo?)|subsp)\.\s+.*/, '')
  end

  def minimum_planting_density_in(unit)
    return nil unless minimum_planting_density

    (minimum_planting_density_value / Measured::Area.new(1, minimum_planting_density_unit).convert_to(unit).value).to_f
  end
end
