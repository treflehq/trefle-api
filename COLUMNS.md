# Table name: species

id                                :bigint           not null, primary key
active_growth_period              :string(255)
adapted_to_coarse_textured_soils  :boolean
adapted_to_fine_textured_soils    :boolean
adapted_to_medium_textured_soils  :boolean
after_harvest_regrowth_rate       :string(255)
anaerobic_tolerance               :string(255)
berry_nut_seed_product            :boolean
bloat                             :string(255)
c_n_ratio                         :string(255)
caco_3_tolerance                  :string(255)
christmas_tree_product            :boolean
cold_stratification_required      :boolean
commercial_availability           :string(255)
coppice_potential                 :boolean
drought_tolerance                 :string(255)
edible                            :boolean
fall_conspicuous                  :boolean
family_common_name                :string(255)
fertility_requirement             :string(255)
fire_resistance                   :boolean
fire_tolerance                    :string(255)
flower_conspicuous                :boolean
fodder_product                    :boolean
foliage_color                     :string(255)
foliage_porosity_summer           :string(255)
foliage_porosity_winter           :string(255)
foliage_texture                   :string(255)
frost_free_days_minimum           :float
fruit_conspicuous                 :boolean
fruit_seed_abundance              :string(255)
fruit_seed_persistence            :boolean
fuelwood_product                  :string(255)
gbif_score                        :integer          default(0), not null
growth_form                       :string(255)
growth_habit                      :string(255)
growth_rate                       :string(255)
hedge_tolerance                   :string(255)
images_count                      :integer          default(0), not null
inserted_at                       :datetime         not null
known_allelopath                  :boolean
leaf_retention                    :boolean
lifespan                          :string(255)
low_growing_grass                 :boolean
lumber_product                    :boolean
moisture_use                      :string(255)
native_status                     :string(255)
naval_store_product               :boolean
nitrogen_fixation                 :string(255)
nursery_stock_product             :boolean
observations                      :text
palatable_browse_animal           :string(255)
palatable_graze_animal            :string(255)
palatable_human                   :boolean
ph_maximum                        :float
ph_minimum                        :float
post_product                      :boolean
protein_potential                 :string(255)
pulpwood_product                  :boolean
rank                              :integer
resprout_ability                  :boolean
reviewed_at                       :datetime
root_depth_minimum_inches         :float
salinity_tolerance                :string(255)
seed_spread_rate                  :string(255)
seedling_vigor                    :string(255)
seeds_per_pound                   :float
shape_and_orientation             :string(255)
small_grain                       :boolean
sources_count                     :integer          default(0), not null
synonyms_count                    :integer          default(0), not null
vegetable                         :boolean
vegetative_spread_rate            :string(255)
veneer_product                    :boolean

# ok
scientific_name                   :string(255)
slug                              :string(255)
year                              :integer
created_at                        :datetime
updated_at                        :datetime         not null
genus_id                          :integer
main_species_id                   :integer
plant_id                          :bigint
author                            :string(255)
common_name                       :string(255)
bibliography                      :text
complete_data                     :boolean

maximum_height_unit               :string(12)
maximum_height_value              :decimal(, )
maximum_precipitation_unit        :string(12)
maximum_precipitation_value       :decimal(, )
maximum_temperature_deg_c         :decimal(, )
maximum_temperature_deg_f         :decimal(, )
minimum_planting_density_unit     :string(12)
minimum_planting_density_value    :decimal(, )
minimum_precipitation_unit        :string(12)
minimum_precipitation_value       :decimal(, )
minimum_root_depth_unit           :string(12)
minimum_root_depth_value          :decimal(, )
minimum_temperature_deg_c         :decimal(, )
minimum_temperature_deg_f         :decimal(, )
average_mature_height_unit        :string(12)
average_mature_height_value       :decimal(, )


## Deprecated & Migrated
usda_name                         :string(255)
usda_synonym                      :string(255)
species_type                      :string(255)
synonym_of_id                     :integer

## To Deprecate & Migrate
status                            :string(255)

`replaced by duration_fl flag`
duration                          :string(255)

`replaced by propagated_by flag`
propagated_by_bare_root           :boolean
propagated_by_bulbs               :boolean
propagated_by_container           :boolean
propagated_by_corms               :boolean
propagated_by_cuttings            :boolean
propagated_by_seed                :boolean
propagated_by_sod                 :boolean
propagated_by_sprigs              :boolean
propagated_by_tubers              :boolean

`replaced by minimum_*`
planting_density_per_acre_maximum :float
planting_density_per_acre_minimum :float
precipitation_maximum             :float
precipitation_minimum             :float
temperature_minimum_deg_f         :float
height_at_base_age_max_ft         :float
height_mature_ft                  :float

`replaced by growth_months flag`
active_growth_period

`replaced by fruit_months flag`
fruit_seed_period_begin           :string(255)
fruit_seed_period_end             :string(255)

`replaced by bloom_months flag`
bloom_period                      :string(255)

`replaced by flags`
flower_color                      :string(255)
fruit_color                       :string(255)

`replaced by s_status`
status

`replaced by s_toxicity`
toxicity

`replaced_by light`
shade_tolerance                   :string(255)

## Dont know what to do

fruit_seed_abundance
fire_resistance
fire_tolerance
fall_conspicuous
flower_conspicuous
native_status
frost_free_days_minimum

## New flags field

duration_fl
propagated_by
growth_months
bloom_months
fruit_months