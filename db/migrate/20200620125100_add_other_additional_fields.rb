class AddOtherAdditionalFields < ActiveRecord::Migration[6.0]
  def change
    add_column :species, :soil_texture, :integer
    add_column :species, :soil_salinity, :integer
    add_column :species, :soil_nutriments, :integer

    remove_column :species, :foliage_color, :string
    rename_column :species, :f_foliage_color, :foliage_color
    rename_column :species, :usda_name, :z_leg_usda_name
    rename_column :species, :usda_synonym, :z_leg_usda_synonym
    rename_column :species, :shade_tolerance, :z_leg_shade_tolerance
    rename_column :species, :salinity_tolerance, :z_leg_salinity_tolerance
    rename_column :species, :fertility_requirement, :z_leg_fertility_requirement
    rename_column :species, :fodder_product, :z_leg_fodder_product
    rename_column :species, :lumber_product, :z_leg_lumber_product
  end
end
