# == Schema Information
#
# Table name: species_proposals
#
#  id                                :bigint           not null, primary key
#  active_growth_period              :string(255)
#  adapted_to_coarse_textured_soils  :boolean          default(FALSE), not null
#  adapted_to_fine_textured_soils    :boolean          default(FALSE), not null
#  adapted_to_medium_textured_soils  :boolean          default(FALSE), not null
#  after_harvest_regrowth_rate       :string(255)
#  anaerobic_tolerance               :string(255)
#  author                            :string(255)
#  berry_nut_seed_product            :boolean          default(FALSE), not null
#  bibliography                      :string(255)
#  bloat                             :string(255)
#  bloom_period                      :string(255)
#  c_n_ratio                         :string(255)
#  caco_3_tolerance                  :string(255)
#  change_status                     :string(255)      default("pending"), not null
#  change_type                       :string(255)      not null
#  christmas_tree_product            :boolean          default(FALSE), not null
#  cold_stratification_required      :boolean          default(FALSE), not null
#  commercial_availability           :string(255)
#  common_name                       :string(255)
#  complete_data                     :boolean          default(FALSE), not null
#  coppice_potential                 :boolean          default(FALSE), not null
#  drought_tolerance                 :string(255)
#  duration                          :string(255)
#  fall_conspicuous                  :boolean          default(FALSE), not null
#  family_common_name                :string(255)
#  fertility_requirement             :string(255)
#  fire_resistance                   :boolean          default(FALSE), not null
#  fire_tolerance                    :string(255)
#  flower_color                      :string(255)
#  flower_conspicuous                :boolean          default(FALSE), not null
#  fodder_product                    :boolean          default(FALSE), not null
#  foliage_color                     :string(255)
#  foliage_porosity_summer           :string(255)
#  foliage_porosity_winter           :string(255)
#  foliage_texture                   :string(255)
#  frost_free_days_minimum           :float
#  fruit_color                       :string(255)
#  fruit_conspicuous                 :boolean          default(FALSE), not null
#  fruit_seed_abundance              :string(255)
#  fruit_seed_period_begin           :string(255)
#  fruit_seed_period_end             :string(255)
#  fruit_seed_persistence            :boolean          default(FALSE), not null
#  fuelwood_product                  :string(255)
#  growth_form                       :string(255)
#  growth_habit                      :string(255)
#  growth_rate                       :string(255)
#  hedge_tolerance                   :string(255)
#  height_at_base_age_max_ft         :float
#  height_mature_ft                  :float
#  inserted_at                       :datetime         not null
#  known_allelopath                  :boolean          default(FALSE), not null
#  leaf_retention                    :boolean          default(FALSE), not null
#  lifespan                          :string(255)
#  low_growing_grass                 :boolean          default(FALSE), not null
#  lumber_product                    :boolean          default(FALSE), not null
#  moisture_use                      :string(255)
#  native_status                     :string(255)
#  naval_store_product               :boolean          default(FALSE), not null
#  nitrogen_fixation                 :string(255)
#  nursery_stock_product             :boolean          default(FALSE), not null
#  palatable_browse_animal           :string(255)
#  palatable_graze_animal            :string(255)
#  palatable_human                   :boolean          default(FALSE), not null
#  ph_maximum                        :float
#  ph_minimum                        :float
#  planting_density_per_acre_maximum :float
#  planting_density_per_acre_minimum :float
#  post_product                      :boolean          default(FALSE), not null
#  precipitation_maximum             :float
#  precipitation_minimum             :float
#  propogated_by_bare_root           :boolean          default(FALSE), not null
#  propogated_by_bulbs               :boolean          default(FALSE), not null
#  propogated_by_container           :boolean          default(FALSE), not null
#  propogated_by_corms               :boolean          default(FALSE), not null
#  propogated_by_cuttings            :boolean          default(FALSE), not null
#  propogated_by_seed                :boolean          default(FALSE), not null
#  propogated_by_sod                 :boolean          default(FALSE), not null
#  propogated_by_sprigs              :boolean          default(FALSE), not null
#  propogated_by_tubers              :boolean          default(FALSE), not null
#  protein_potential                 :string(255)
#  pulpwood_product                  :boolean          default(FALSE), not null
#  resprout_ability                  :boolean          default(FALSE), not null
#  root_depth_minimum_inches         :float
#  salinity_tolerance                :string(255)
#  scientific_name                   :string(255)
#  seed_spread_rate                  :string(255)
#  seedling_vigor                    :string(255)
#  seeds_per_pound                   :float
#  shade_tolerance                   :string(255)
#  shape_and_orientation             :string(255)
#  small_grain                       :boolean          default(FALSE), not null
#  species_type                      :string(255)
#  status                            :string(255)
#  temperature_minimum_deg_f         :float
#  toxicity                          :string(255)
#  usda_name                         :string(255)
#  usda_synonym                      :string(255)
#  vegetative_spread_rate            :string(255)
#  veneer_product                    :boolean          default(FALSE), not null
#  year                              :integer
#  updated_at                        :datetime         not null
#  genus_id                          :bigint
#  synonym_of_id                     :integer
#  user_id                           :bigint
#
# Foreign Keys
#
#  species_proposals_genus_id_fkey  (genus_id => genuses.id)
#  species_proposals_user_id_fkey   (user_id => users.id)
#
class SpeciesProposal < ApplicationRecord
  belongs_to :genus
  belongs_to :user
  belongs_to :synonym_of, class_name: 'Species'
end
