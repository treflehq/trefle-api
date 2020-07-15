class RenameSpeciesColumns < ActiveRecord::Migration[6.0]
  def change # rubocop:todo Metrics/MethodLength
    remove_column :species, :status
    rename_column :species, :s_status, :status

    remove_column :species, :toxicity
    rename_column :species, :s_toxicity, :toxicity

    remove_column :species, :foliage_texture
    rename_column :species, :s_foliage_texture, :foliage_texture

    remove_column :species, :flower_color
    rename_column :species, :f_flower_color, :flower_color

    remove_column :species, :fruit_color
    rename_column :species, :f_fruit_color, :fruit_color

    remove_column :species, :height_mature_ft
    remove_column :species, :height_at_base_age_max_ft
    remove_column :species, :root_depth_minimum_inches
    remove_column :species, :planting_density_per_acre_minimum
    remove_column :species, :precipitation_minimum
    remove_column :species, :precipitation_maximum
    remove_column :species, :temperature_minimum_deg_f

    remove_column :species, :propagated_by_bare_root
    remove_column :species, :propagated_by_bulbs
    remove_column :species, :propagated_by_container
    remove_column :species, :propagated_by_corms
    remove_column :species, :propagated_by_cuttings
    remove_column :species, :propagated_by_seed
    remove_column :species, :propagated_by_sod
    remove_column :species, :propagated_by_sprigs
    remove_column :species, :propagated_by_tubers

    remove_column :species, :duration
    rename_column :species, :duration_fl, :duration

    remove_column :species, :active_growth_period
    remove_column :species, :fruit_seed_period_begin
    remove_column :species, :fruit_seed_period_end
    remove_column :species, :bloom_period
  end
end
