# == Schema Information
#
# Table name: species
#
#  id                               :bigint           not null, primary key
#  adapted_to_coarse_textured_soils :boolean
#  adapted_to_fine_textured_soils   :boolean
#  adapted_to_medium_textured_soils :boolean
#  anaerobic_tolerance              :string(255)
#  atmospheric_humidity             :integer
#  author                           :string(255)
#  average_height_cm                :integer
#  bibliography                     :text
#  biological_type                  :integer
#  biological_type_raw              :string
#  bloom_months                     :bigint           default(0), not null
#  c_n_ratio                        :string(255)
#  caco_3_tolerance                 :string(255)
#  checked_at                       :datetime
#  common_name                      :string(255)
#  complete_data                    :boolean
#  completion_ratio                 :integer
#  dissemination                    :integer          default(0), not null
#  dissemination_raw                :string
#  duration                         :bigint           default(0), not null
#  edible                           :boolean
#  edible_part                      :integer          default(0), not null
#  family_common_name               :string(255)
#  family_name                      :string
#  flower_color                     :bigint           default(0), not null
#  flower_conspicuous               :boolean
#  foliage_color                    :bigint           default(0), not null
#  foliage_texture                  :integer
#  frost_free_days_minimum          :float
#  fruit_color                      :bigint           default(0), not null
#  fruit_conspicuous                :boolean
#  fruit_months                     :bigint           default(0), not null
#  fruit_seed_persistence           :boolean
#  fruit_shape                      :integer
#  fruit_shape_raw                  :string
#  full_token                       :text
#  gbif_score                       :integer          default(0), not null
#  genus_name                       :string
#  ground_humidity                  :integer
#  growth_form                      :string(255)
#  growth_habit                     :string(255)
#  growth_months                    :bigint           default(0), not null
#  growth_rate                      :string(255)
#  hardiness_zone                   :integer
#  images_count                     :integer          default(0), not null
#  inflorescence_form               :integer
#  inflorescence_raw                :string
#  inflorescence_type               :integer
#  inserted_at                      :datetime         not null
#  known_allelopath                 :boolean
#  leaf_retention                   :boolean
#  lifespan                         :string(255)
#  light                            :integer
#  ligneous_type                    :integer
#  main_image_url                   :string
#  maturation_order                 :string
#  maturation_order_raw             :string
#  maximum_height_cm                :integer
#  maximum_precipitation_mm         :integer
#  maximum_temperature_deg_c        :decimal(, )
#  maximum_temperature_deg_f        :decimal(, )
#  minimum_precipitation_mm         :integer
#  minimum_root_depth_cm            :integer
#  minimum_temperature_deg_c        :decimal(, )
#  minimum_temperature_deg_f        :decimal(, )
#  nitrogen_fixation                :string(255)
#  observations                     :text
#  ph_maximum                       :float
#  ph_minimum                       :float
#  phylum                           :string
#  planting_days_to_harvest         :integer
#  planting_description             :text
#  planting_row_spacing_cm          :integer
#  planting_sowing_description      :text
#  planting_spread_cm               :integer
#  pollinisation                    :integer          default(0), not null
#  pollinisation_raw                :string
#  propagated_by                    :bigint           default(0), not null
#  protein_potential                :string(255)
#  rank                             :integer
#  reviewed_at                      :datetime
#  scientific_name                  :string(255)
#  sexuality                        :integer          default(0), not null
#  sexuality_raw                    :string
#  shape_and_orientation            :string(255)
#  slug                             :string(255)
#  soil_nutriments                  :integer
#  soil_salinity                    :integer
#  soil_texture                     :integer
#  sources_count                    :integer          default(0), not null
#  status                           :integer
#  synonyms_count                   :integer          default(0), not null
#  token                            :text
#  toxicity                         :integer
#  vegetable                        :boolean
#  wiki_score                       :integer
#  year                             :integer
#  created_at                       :datetime
#  updated_at                       :datetime         not null
#  genus_id                         :integer
#  main_species_id                  :integer
#  plant_id                         :bigint
#
# Indexes
#
#  index_species_on_average_height_cm               (average_height_cm)
#  index_species_on_common_name                     (common_name)
#  index_species_on_family_common_name              (family_common_name)
#  index_species_on_flower_conspicuous              (flower_conspicuous)
#  index_species_on_light                           (light)
#  index_species_on_main_species_id_and_gbif_score  (main_species_id,gbif_score)
#  index_species_on_maximum_height_cm               (maximum_height_cm)
#  index_species_on_minimum_precipitation_mm        (minimum_precipitation_mm)
#  index_species_on_minimum_root_depth_cm           (minimum_root_depth_cm)
#  index_species_on_minimum_temperature_deg_f       (minimum_temperature_deg_f)
#  index_species_on_planting_days_to_harvest        (planting_days_to_harvest)
#  index_species_on_planting_row_spacing_cm         (planting_row_spacing_cm)
#  index_species_on_planting_spread_cm              (planting_spread_cm)
#  index_species_on_slug                            (slug)
#  index_species_on_token                           (token)
#  species_gbif_score_idx                           (gbif_score)
#  species_genus_id_index                           (genus_id)
#  species_main_species_id_index                    (main_species_id)
#  species_plant_id_index                           (plant_id)
#  species_scientific_name_index                    (scientific_name) UNIQUE
#
# Foreign Keys
#
#  species_plant_id_fkey  (plant_id => plants.id)
#
class Species < ApplicationRecord

  extend Pagy::Search
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

  # Elasticsearch search
  include Search::Species

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

  has_many :species_trends, dependent: :destroy
  has_many :species_distributions, dependent: :destroy
  has_many :zones, through: :species_distributions

  accepts_nested_attributes_for :common_names
  accepts_nested_attributes_for :species_distributions
  accepts_nested_attributes_for :synonyms
  accepts_nested_attributes_for :foreign_sources_plants
  accepts_nested_attributes_for :species_images

  counter_culture :plant

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

  flag :edible_part, %i[roots stem leaves flowers fruits seeds tubers]

  before_validation :infer_rank
  before_validation :infer_genus
  before_validation :complete_cache_fields

  before_create :infer_plant

  before_save :update_completion_ratio!
  before_save :regenerate_tokens!

  extend FriendlyId
  friendly_id :scientific_name, use: :slugged

  after_save :setup_main_species

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

  def complete_cache_fields
    self.genus_name = genus&.name
    self.family_name = genus&.family&.name
    self.family_common_name = genus&.family&.common_name
    self.edible = (vegetable || edible_part&.any?)

    return unless main_image_url.nil?

    candidate = species_images.order(score: :desc).where(part: :habit)&.first&.image_url
    candidate ||= species_images.order(score: :desc)&.first&.image_url
    self.main_image_url = candidate if candidate
  end

  def current_completion_percentage
    ignored = [
      *attributes.keys.filter {|e| e.ends_with?('_count') },
      *attributes.keys.filter {|e| e.ends_with?('_raw') },
      'id', 'plant_id', 'genus_id', 'slug',
      'inserted_at', 'updated_at', 'created_at', 'checked_at',
      'token', 'full_token', 'complete_data', 'completion_ratio'
    ]

    total = attributes.without(ignored).keys.count
    complete = attributes.without(ignored).values.reject {|e| e.nil? || e.blank? || e == 0 }.count

    Rails.logger.debug("[current_completion_percentage] #{complete} complete fields over #{total} fields")
    ((complete.to_f / total.to_f).to_f * 100).to_i # rubocop:todo Style/FloatDivision
  end

  def update_completion_ratio!
    self.completion_ratio = current_completion_percentage
    self.complete_data = (completion_ratio > 50)
  end

  # Theses are tokens used for integrity and search
  def regenerate_tokens!
    # This one is for integrity, to avoir same species with similar names
    self.token = computed_token

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

  def computed_token
    ::Utils::ScientificName.tokenize(scientific_name)
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

    pattrs = plant&.reload ? plant.reload.attributes.slice(*merge_attrs).compact : {}
    attributes.slice(*merge_attrs).compact.merge(pattrs)
  end

  def merge_species_over_plant
    merge_attrs = PLANTS_ATTRIBUTES
    pattrs = plant&.reload ? plant.reload.attributes.slice(*merge_attrs).compact : {}
    pattrs.merge(attributes.slice(*merge_attrs).compact)
  end

  def merge_from_complete_data(species_from)
    merge_attrs = merge_attributes_keys

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

  def merge_attributes
    zero_based_attrs = %w[
      bloom_months
      dissemination
      duration
      edible_part
      flower_color
      foliage_color
      fruit_color
      fruit_months
      gbif_score
      growth_months
      images_count
      pollinisation
      propagated_by
      sexuality
      sources_count
      synonyms_count
    ]
    attributes
      .slice(*merge_attributes_keys)
      .reject {|k, v| zero_based_attrs.include?(k) && v.zero? }
      .compact
  end

  def merge_attributes_keys
    attributes.keys.without(
      # We want all species fields, without theses ones
      %w[
        id slug inserted_at updated_at plant_id scientific_name rank
        checked_at token full_token created_at reviewed_at complete_data
        sources_count images_count synonyms_count gbif_score
      ]
    )
  end

  def self.root_scientific_name(full)
    full.gsub(/\s+(var|ssp|subvar|(fo?)|subsp)\.\s+.*/, '')
  end

  def minimum_planting_density_in(unit)
    return nil unless minimum_planting_density

    (minimum_planting_density_value / Measured::Area.new(1, minimum_planting_density_unit).convert_to(unit).value).to_f
  end
end
