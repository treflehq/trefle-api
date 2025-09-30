class AddAdditionalFields < ActiveRecord::Migration[6.0]
  # rubocop:todo Metrics/MethodLength
  def self.up # rubocop:todo Metrics/AbcSize # rubocop:todo Metrics/MethodLength # rubocop:todo Metrics/MethodLength # rubocop:todo Metrics/MethodLength
    add_column :species, :f_foliage_color, :integer, null: false, default: 0, limit: 8
    # Species.where(status: 'Accepted').update_all(s_status: :accepted)
    # Species.where(status: 'Unknown').update_all(s_status: :unknown)

    # Species.where(toxicity: 'None').update_all(s_toxicity: :none)
    # Species.where(toxicity: 'Slight').update_all(s_toxicity: :low)
    # Species.where(toxicity: 'Moderate').update_all(s_toxicity: :medium)
    # Species.where(toxicity: 'Severe').update_all(s_toxicity: :high)

    # Species.where(foliage_texture: 'Fine').update_all(s_foliage_texture: :fine)
    # Species.where(foliage_texture: 'Medium').update_all(s_foliage_texture: :medium)
    # Species.where(foliage_texture: 'Coarse').update_all(s_foliage_texture: :coarse)

    # Species.where(foliage_texture: 'Fine').update_all(s_foliage_texture: :fine)
    # Species.where(foliage_texture: 'Medium').update_all(s_foliage_texture: :medium)
    # Species.where(foliage_texture: 'Coarse').update_all(s_foliage_texture: :coarse)

    # Species.group(:flower_color).count.keys.compact.map do |str_color|
    #   puts "Migrating #{str_color} flower colors"
    #   Species.where(flower_color: str_color).update_all(f_flower_color: Species.f_flower_colors.maps[str_color.underscore.to_sym])
    # end

    rename_column :species, :after_harvest_regrowth_rate, :z_leg_after_harvest_regrowth_rate
    rename_column :species, :berry_nut_seed_product, :z_leg_berry_nut_seed_product
    rename_column :species, :bloat, :z_leg_bloat
    rename_column :species, :christmas_tree_product, :z_leg_christmas_tree_product
    rename_column :species, :cold_stratification_required, :z_leg_cold_stratification_required
    rename_column :species, :commercial_availability, :z_leg_commercial_availability
    rename_column :species, :coppice_potential, :z_leg_coppice_potential
    rename_column :species, :drought_tolerance, :z_leg_drought_tolerance
    rename_column :species, :fall_conspicuous, :z_leg_fall_conspicuous
    rename_column :species, :fire_resistance, :z_leg_fire_resistance
    rename_column :species, :fire_tolerance, :z_leg_fire_tolerance
    rename_column :species, :foliage_porosity_summer, :z_leg_foliage_porosity_summer
    rename_column :species, :foliage_porosity_winter, :z_leg_foliage_porosity_winter
    rename_column :species, :fruit_seed_abundance, :z_leg_fruit_seed_abundance
    rename_column :species, :fuelwood_product, :z_leg_fuelwood_product
    rename_column :species, :low_growing_grass, :z_leg_low_growing_grass
    rename_column :species, :hedge_tolerance, :z_leg_hedge_tolerance
    rename_column :species, :moisture_use, :z_leg_moisture_use
    rename_column :species, :naval_store_product, :z_leg_naval_store_product
    rename_column :species, :nursery_stock_product, :z_leg_nursery_stock_product
    rename_column :species, :palatable_browse_animal, :z_leg_palatable_browse_animal
    rename_column :species, :palatable_graze_animal, :z_leg_palatable_graze_animal
    rename_column :species, :palatable_human, :z_leg_palatable_human
    rename_column :species, :post_product, :z_leg_post_product
    rename_column :species, :pulpwood_product, :z_leg_pulpwood_product
    rename_column :species, :resprout_ability, :z_leg_resprout_ability
    rename_column :species, :seed_spread_rate, :z_leg_seed_spread_rate
    rename_column :species, :seedling_vigor, :z_leg_seedling_vigor
    rename_column :species, :seeds_per_pound, :z_leg_seeds_per_pound
    rename_column :species, :small_grain, :z_leg_small_grain
    rename_column :species, :vegetative_spread_rate, :z_leg_vegetative_spread_rate
    rename_column :species, :veneer_product, :z_leg_veneer_product

    remove_column :species, :planting_density_per_acre_maximum

    # Ex:- rename_column("admin_users", "pasword","hashed_pasword")
    Species.group(:foliage_color).count.keys.compact.map do |str_color|
      puts "Migrating #{str_color} fruit colors"
      color = {
        'Dark Green' => :green,
        'Gray-Green' => :green,
        'Green' => :green,
        'Red' => :red,
        'White-Gray' => :grey,
        'Yellow-Green' => :yellow
      }[str_color]
      Species.where(foliage_color: str_color).update_all(f_foliage_color: Species.f_foliage_colors.maps[color])
    end

    # Species.where(foliage_texture: 'Fine').update_all(s_foliage_texture: :fine)
    # Species.where(foliage_texture: 'Medium').update_all(s_foliage_texture: :medium)
    # Species.where(foliage_texture: 'Coarse').update_all(s_foliage_texture: :coarse)
  end
  # rubocop:enable Metrics/MethodLength

  def self.down
    remove_column :species, :f_foliage_color
  end
end
