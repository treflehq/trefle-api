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
#  index_species_on_author                           (author)
#  index_species_on_average_height_cm                (average_height_cm)
#  index_species_on_common_name                      (common_name)
#  index_species_on_family_common_name               (family_common_name)
#  index_species_on_flower_conspicuous               (flower_conspicuous)
#  index_species_on_genus_name                       (genus_name)
#  index_species_on_light                            (light)
#  index_species_on_main_species_id_and_common_name  (main_species_id,common_name)
#  index_species_on_main_species_id_and_gbif_score   (main_species_id,gbif_score)
#  index_species_on_maximum_height_cm                (maximum_height_cm)
#  index_species_on_minimum_precipitation_mm         (minimum_precipitation_mm)
#  index_species_on_minimum_root_depth_cm            (minimum_root_depth_cm)
#  index_species_on_minimum_temperature_deg_f        (minimum_temperature_deg_f)
#  index_species_on_planting_days_to_harvest         (planting_days_to_harvest)
#  index_species_on_planting_row_spacing_cm          (planting_row_spacing_cm)
#  index_species_on_planting_spread_cm               (planting_spread_cm)
#  index_species_on_slug                             (slug)
#  index_species_on_token                            (token)
#  species_gbif_score_idx                            (gbif_score)
#  species_genus_id_index                            (genus_id)
#  species_main_species_id_index                     (main_species_id)
#  species_plant_id_index                            (plant_id)
#  species_scientific_name_index                     (scientific_name) UNIQUE
#
# Foreign Keys
#
#  species_plant_id_fkey  (plant_id => plants.id)
#

class SpeciesSerializer < BaseSerializer

  attributes :common_name, :slug, :scientific_name,
             :year, :bibliography, :author, :status,
             :rank, :family_common_name, :family,
             :genus_id, :genus,
             :observations, :images, :common_names,
             :distributions, :distribution,
             :duration,
             :links, :image_url,
             :vegetable, :edible, :edible_part

  attributes :flower, :foliage,
             :fruit_or_seed, :specifications,
             :growth # , :propagation, :products

  # has_one :plant, serializer: PlantLightSerializer

  has_many :synonyms, serializer: SynonymSerializer

  has_many :foreign_sources_plants, serializer: ForeignSourcesPlantSerializer, name: :sources
  # has_many :species_distributions, serializer: SpeciesDistributionSerializer, name: :distribution

  def image_url
    object.main_image_url
  end

  def genus
    object.genus_name || object.genus.name
  end

  def family
    object.family_name || object.genus&.family&.name
  end

  def duration
    render_flag(:duration)
  end

  def edible_part
    render_flag(:edible_part)
  end

  def edible
    object.edible_part&.any? || object.vegetable
  end

  # def propagated_by
  #   render_flag(:propagated_by)
  # end

  def images
    {
      flower: Panko::ArraySerializer.new(object.species_images.flower_part, each_serializer: SpeciesImageSerializer).to_a,
      leaf: Panko::ArraySerializer.new(object.species_images.leaf_part, each_serializer: SpeciesImageSerializer).to_a,
      habit: Panko::ArraySerializer.new(object.species_images.habit_part, each_serializer: SpeciesImageSerializer).to_a,
      fruit: Panko::ArraySerializer.new(object.species_images.fruit_part, each_serializer: SpeciesImageSerializer).to_a,
      bark: Panko::ArraySerializer.new(object.species_images.bark_part, each_serializer: SpeciesImageSerializer).to_a,
      other: Panko::ArraySerializer.new(object.species_images.other_part, each_serializer: SpeciesImageSerializer).to_a
    }
  end

  def common_names
    object.common_names.group_by(&:lang).transform_values {|e| e.pluck(:name) }
  end

  def distribution
    object.species_distributions.joins(:zone).group_by(&:establishment).transform_values {|e| e.map {|r| r.zone.name } }
  end

  def distributions
    object.species_distributions.joins(:zone).group_by(&:establishment).transform_values do |e|
      e.map {|r| ZoneLightSerializer.new.serialize(r.zone) }
    end
  end

  def flower
    {
      color: render_flag(:flower_color),
      conspicuous: object.flower_conspicuous
    }
  end

  def foliage
    {
      texture: object.foliage_texture,
      color: render_flag(:foliage_color),
      leaf_retention: object.leaf_retention
    }
  end

  def fruit_or_seed
    {
      conspicuous: object.fruit_conspicuous,
      color: render_flag(:fruit_color),
      shape: object.fruit_shape,
      seed_persistence: object.fruit_seed_persistence
    }
  end

  def specifications
    {
      # c_n_ratio: object.c_n_ratio, @TODO
      ligneous_type: object.ligneous_type,
      growth_form: object.growth_form,
      growth_habit: object.growth_habit,
      growth_rate: object.growth_rate,
      # known_allelopath: object.known_allelopath, @TODO
      # lifespan: object.lifespan,
      average_height: {
        # ft: object&.average_height&.convert_to('ft')&.value&.to_i,
        cm: object&.average_height_cm
      },
      maximum_height: {
        # ft: object&.maximum_height&.convert_to('ft')&.value&.to_i,
        cm: object&.maximum_height_cm
      },
      nitrogen_fixation: object.nitrogen_fixation,
      shape_and_orientation: object.shape_and_orientation,
      toxicity: object.toxicity
    }
  end

  # rubocop:todo Metrics/MethodLength
  def growth # rubocop:todo Metrics/AbcSize # rubocop:todo Metrics/MethodLength # rubocop:todo Metrics/MethodLength # rubocop:todo Metrics/MethodLength
    {
      # anaerobic_tolerance: object.anaerobic_tolerance,
      # caco_3_tolerance: object.caco_3_tolerance,
      # frost_free_days_minimum: object.frost_free_days_minimum,
      description: object.planting_description,
      sowing: object.planting_sowing_description,
      days_to_harvest: object.planting_days_to_harvest,
      row_spacing: {
        cm: object.planting_row_spacing_cm
      },
      spread: {
        cm: object.planting_spread_cm
      },
      ph_maximum: object.ph_maximum,
      ph_minimum: object.ph_minimum,
      # minimum_planting_density: {
      #   per_acre: object&.minimum_planting_density_in('acre'),
      #   per_sqm: object&.minimum_planting_density_in('m2')
      # },
      light: object.light,
      atmospheric_humidity: object.atmospheric_humidity,
      growth_months: render_flag(:growth_months),
      bloom_months: render_flag(:bloom_months),
      fruit_months: render_flag(:fruit_months),

      minimum_precipitation: {
        # inches: object&.minimum_precipitation&.convert_to('in')&.value&.to_i,
        mm: object&.minimum_precipitation_mm
      },
      maximum_precipitation: {
        # inches: object&.maximum_precipitation&.convert_to('in')&.value&.to_i,
        mm: object&.maximum_precipitation_mm
      },
      minimum_root_depth: {
        # inches: object&.minimum_root_depth&.convert_to('in')&.value&.to_i,
        cm: object&.minimum_root_depth_cm
      },
      minimum_temperature: {
        deg_f: object.minimum_temperature_deg_f&.to_i,
        deg_c: object.minimum_temperature_deg_c&.to_i
      },
      maximum_temperature: {
        deg_f: object.maximum_temperature_deg_f&.to_i,
        deg_c: object.maximum_temperature_deg_c&.to_i
      },
      soil_nutriments: object.soil_nutriments,
      soil_salinity: object.soil_salinity,
      soil_texture: object.soil_texture_before_type_cast,
      soil_humidity: object.ground_humidity
      # hardiness_zone: object.hardiness_zone, @TODO
      # adaptation: {
      #   medium: object.adapted_to_medium_textured_soils,
      #   fine: object.adapted_to_fine_textured_soils,
      #   coarse: object.adapted_to_coarse_textured_soils
      # }
    }
  end
  # rubocop:enable Metrics/MethodLength

  def links
    {
      self: url_helpers.api_v1_species_path(object),
      plant: url_helpers.api_v1_plant_path(object.plant.slug),
      genus: url_helpers.api_v1_genus_path(object.genus.slug)
    }
  end

end
