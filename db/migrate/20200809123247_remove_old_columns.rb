class RemoveOldColumns < ActiveRecord::Migration[6.0]
  def change
    remove_column :species, :z_leg_after_harvest_regrowth_rate
    remove_column :species, :z_leg_berry_nut_seed_product
    remove_column :species, :z_leg_bloat
    remove_column :species, :z_leg_christmas_tree_product
    remove_column :species, :z_leg_cold_stratification_required
    remove_column :species, :z_leg_commercial_availability
    remove_column :species, :z_leg_coppice_potential
    remove_column :species, :z_leg_drought_tolerance
    remove_column :species, :z_leg_fall_conspicuous
    remove_column :species, :z_leg_fertility_requirement
    remove_column :species, :z_leg_fire_resistance
    remove_column :species, :z_leg_fire_tolerance
    remove_column :species, :z_leg_fodder_product
    remove_column :species, :z_leg_foliage_porosity_summer
    remove_column :species, :z_leg_foliage_porosity_winter
    remove_column :species, :z_leg_fruit_seed_abundance
    remove_column :species, :z_leg_fuelwood_product
    remove_column :species, :z_leg_hedge_tolerance
    remove_column :species, :z_leg_low_growing_grass
    remove_column :species, :z_leg_lumber_product
    remove_column :species, :z_leg_moisture_use
    remove_column :species, :z_leg_native_status
    remove_column :species, :z_leg_naval_store_product
    remove_column :species, :z_leg_nursery_stock_product
    remove_column :species, :z_leg_palatable_browse_animal
    remove_column :species, :z_leg_palatable_graze_animal
    remove_column :species, :z_leg_palatable_human
    remove_column :species, :z_leg_post_product
    remove_column :species, :z_leg_pulpwood_product
    remove_column :species, :z_leg_resprout_ability
    remove_column :species, :z_leg_salinity_tolerance
    remove_column :species, :z_leg_seed_spread_rate
    remove_column :species, :z_leg_seedling_vigor
    remove_column :species, :z_leg_seeds_per_pound
    remove_column :species, :z_leg_shade_tolerance
    remove_column :species, :z_leg_small_grain
    remove_column :species, :z_leg_usda_name
    remove_column :species, :z_leg_usda_synonym
    remove_column :species, :z_leg_vegetative_spread_rate
    remove_column :species, :z_leg_veneer_product
    remove_column :species, :maximum_height_value
    remove_column :species, :maximum_height_unit
    add_column :species, :completion_ratio, :integer
  end
end
