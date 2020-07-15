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
FactoryBot.define do
  factory :species do
    scientific_name { Faker::Space.genus }
  end
end
