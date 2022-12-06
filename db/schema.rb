# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2022_12_06_140236) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_stat_statements"
  enable_extension "plpgsql"
  enable_extension "timescaledb"

  create_table "common_names", force: :cascade do |t|
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.string "name"
    t.string "lang"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id"], name: "index_common_names_on_record_type_and_record_id"
  end

  create_table "division_classes", force: :cascade do |t|
    t.string "name", limit: 255
    t.string "slug", limit: 255
    t.bigint "division_id"
    t.datetime "inserted_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "created_at", precision: nil
    t.index ["division_id"], name: "division_classes_division_id_index"
    t.index ["name"], name: "division_classes_name_index", unique: true
  end

  create_table "division_orders", force: :cascade do |t|
    t.string "name", limit: 255
    t.string "slug", limit: 255
    t.bigint "division_class_id"
    t.datetime "inserted_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "created_at", precision: nil
    t.index ["name"], name: "division_orders_name_index", unique: true
    t.index ["slug"], name: "division_orders_slug_index", unique: true
  end

  create_table "divisions", force: :cascade do |t|
    t.string "name", limit: 255
    t.string "slug", limit: 255
    t.bigint "subkingdom_id"
    t.datetime "inserted_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "created_at", precision: nil
    t.index ["name"], name: "divisions_name_index", unique: true
    t.index ["slug"], name: "divisions_slug_index", unique: true
  end

  create_table "families", force: :cascade do |t|
    t.string "name", limit: 255
    t.string "slug", limit: 255
    t.string "common_name", limit: 255
    t.bigint "division_order_id"
    t.bigint "major_group_id"
    t.datetime "inserted_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "created_at", precision: nil
    t.index ["name"], name: "families_name_index", unique: true
    t.index ["slug"], name: "families_slug_index", unique: true
  end

  create_table "foreign_sources", force: :cascade do |t|
    t.string "name", limit: 255
    t.string "slug", limit: 255
    t.string "url", limit: 255
    t.datetime "inserted_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.text "copyright_template"
    t.datetime "created_at", precision: nil
    t.index ["name"], name: "foreign_sources_name_index", unique: true
    t.index ["slug"], name: "foreign_sources_slug_index", unique: true
  end

  create_table "foreign_sources_plants", force: :cascade do |t|
    t.datetime "last_update", precision: nil, default: -> { "now()" }
    t.bigint "species_id"
    t.bigint "foreign_source_id"
    t.string "fid", limit: 255
    t.datetime "inserted_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "created_at", precision: nil
    t.string "record_type"
    t.bigint "record_id"
    t.index ["fid"], name: "index_foreign_sources_plants_on_fid"
    t.index ["foreign_source_id"], name: "foreign_sources_plants_foreign_source_id_index"
    t.index ["record_type", "record_id"], name: "index_foreign_sources_plants_on_record_type_and_record_id"
    t.index ["species_id", "fid", "foreign_source_id"], name: "foreign_sources_plants_species_id_fid_foreign_source_id_index", unique: true
  end

  create_table "genuses", force: :cascade do |t|
    t.string "name", limit: 255
    t.string "slug", limit: 255
    t.bigint "family_id"
    t.datetime "inserted_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "created_at", precision: nil
    t.index ["family_id"], name: "genuses_family_id_index"
    t.index ["name"], name: "genuses_name_index", unique: true
    t.index ["slug"], name: "genuses_slug_index", unique: true
  end

  create_table "kingdoms", force: :cascade do |t|
    t.string "name", limit: 255
    t.string "slug", limit: 255
    t.datetime "inserted_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "created_at", precision: nil
    t.index ["name"], name: "kingdoms_name_index", unique: true
    t.index ["slug"], name: "kingdoms_slug_index", unique: true
  end

  create_table "major_groups", force: :cascade do |t|
    t.string "name", limit: 255
    t.string "slug", limit: 255
    t.datetime "inserted_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "created_at", precision: nil
    t.index ["name"], name: "major_groups_name_index", unique: true
    t.index ["slug"], name: "major_groups_slug_index", unique: true
  end

  create_table "old_species", id: false, force: :cascade do |t|
    t.bigint "id"
    t.integer "year"
    t.text "bibliography"
    t.string "author", limit: 255
    t.string "scientific_name", limit: 255
    t.string "status", limit: 255
    t.bigint "plant_id"
    t.string "slug", limit: 255
    t.datetime "inserted_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.boolean "fruit_conspicuous"
    t.boolean "coppice_potential"
    t.string "fruit_seed_period_end", limit: 255
    t.boolean "resprout_ability"
    t.boolean "propagated_by_sprigs"
    t.boolean "propagated_by_cuttings"
    t.boolean "fodder_product"
    t.float "precipitation_minimum"
    t.string "toxicity", limit: 255
    t.string "foliage_texture", limit: 255
    t.string "fruit_seed_abundance", limit: 255
    t.boolean "fire_resistance"
    t.float "height_at_base_age_max_ft"
    t.boolean "fall_conspicuous"
    t.string "fire_tolerance", limit: 255
    t.float "ph_minimum"
    t.boolean "propagated_by_container"
    t.boolean "flower_conspicuous"
    t.string "native_status", limit: 255
    t.string "fuelwood_product", limit: 255
    t.float "frost_free_days_minimum"
    t.string "growth_habit", limit: 255
    t.string "protein_potential", limit: 255
    t.float "planting_density_per_acre_maximum"
    t.float "root_depth_minimum_inches"
    t.boolean "adapted_to_medium_textured_soils"
    t.string "growth_form", limit: 255
    t.string "after_harvest_regrowth_rate", limit: 255
    t.string "drought_tolerance", limit: 255
    t.string "salinity_tolerance", limit: 255
    t.string "fertility_requirement", limit: 255
    t.string "foliage_color", limit: 255
    t.string "nitrogen_fixation", limit: 255
    t.string "commercial_availability", limit: 255
    t.string "anaerobic_tolerance", limit: 255
    t.string "lifespan", limit: 255
    t.boolean "veneer_product"
    t.string "bloat", limit: 255
    t.float "precipitation_maximum"
    t.float "planting_density_per_acre_minimum"
    t.string "foliage_porosity_winter", limit: 255
    t.float "height_mature_ft"
    t.float "ph_maximum"
    t.boolean "christmas_tree_product"
    t.string "shape_and_orientation", limit: 255
    t.string "shade_tolerance", limit: 255
    t.string "usda_synonym", limit: 255
    t.boolean "pulpwood_product"
    t.boolean "small_grain"
    t.boolean "low_growing_grass"
    t.boolean "berry_nut_seed_product"
    t.string "vegetative_spread_rate", limit: 255
    t.boolean "propagated_by_bare_root"
    t.boolean "propagated_by_sod"
    t.string "fruit_seed_period_begin", limit: 255
    t.string "palatable_browse_animal", limit: 255
    t.string "foliage_porosity_summer", limit: 255
    t.float "seeds_per_pound"
    t.boolean "adapted_to_fine_textured_soils"
    t.string "hedge_tolerance", limit: 255
    t.boolean "post_product"
    t.string "growth_rate", limit: 255
    t.boolean "propagated_by_seed"
    t.string "fruit_color", limit: 255
    t.boolean "nursery_stock_product"
    t.string "seedling_vigor", limit: 255
    t.boolean "cold_stratification_required"
    t.string "palatable_graze_animal", limit: 255
    t.string "bloom_period", limit: 255
    t.boolean "fruit_seed_persistence"
    t.boolean "propagated_by_bulbs"
    t.string "active_growth_period", limit: 255
    t.string "c_n_ratio", limit: 255
    t.string "duration", limit: 255
    t.string "flower_color", limit: 255
    t.boolean "leaf_retention"
    t.boolean "known_allelopath"
    t.boolean "palatable_human"
    t.boolean "propagated_by_tubers"
    t.string "moisture_use", limit: 255
    t.boolean "lumber_product"
    t.boolean "adapted_to_coarse_textured_soils"
    t.boolean "propagated_by_corms"
    t.float "temperature_minimum_deg_f"
    t.boolean "naval_store_product"
    t.string "seed_spread_rate", limit: 255
    t.string "caco_3_tolerance", limit: 255
    t.string "species_type", limit: 255
    t.integer "genus_id"
    t.integer "main_species_id"
    t.string "usda_name", limit: 255
    t.string "family_common_name", limit: 255
    t.string "common_name", limit: 255
    t.boolean "complete_data"
    t.integer "synonym_of_id"
    t.text "observations"
    t.boolean "vegetable"
    t.boolean "edible"
    t.datetime "reviewed_at", precision: nil
    t.datetime "created_at", precision: nil
    t.decimal "average_mature_height_value"
    t.string "average_mature_height_unit", limit: 12
    t.decimal "maximum_height_value"
    t.string "maximum_height_unit", limit: 12
    t.decimal "minimum_root_depth_value"
    t.string "minimum_root_depth_unit", limit: 12
    t.decimal "minimum_planting_density_value"
    t.string "minimum_planting_density_unit", limit: 12
    t.decimal "minimum_precipitation_value"
    t.string "minimum_precipitation_unit", limit: 12
    t.decimal "maximum_precipitation_value"
    t.string "maximum_precipitation_unit", limit: 12
    t.decimal "minimum_temperature_deg_f"
    t.decimal "minimum_temperature_deg_c"
    t.decimal "maximum_temperature_deg_f"
    t.decimal "maximum_temperature_deg_c"
    t.integer "rank"
    t.integer "sources_count"
    t.integer "images_count"
    t.integer "synonyms_count"
    t.integer "gbif_score"
    t.bigint "duration_fl"
    t.bigint "propagated_by"
    t.bigint "growth_months"
    t.bigint "bloom_months"
    t.bigint "fruit_months"
    t.index ["complete_data"], name: "index_old_species_on_complete_data"
    t.index ["family_common_name"], name: "index_old_species_on_family_common_name"
    t.index ["id"], name: "index_old_species_on_id"
    t.index ["main_species_id"], name: "index_old_species_on_main_species_id"
    t.index ["temperature_minimum_deg_f"], name: "index_old_species_on_temperature_minimum_deg_f"
  end

  create_table "plants", force: :cascade do |t|
    t.string "slug", limit: 255
    t.integer "year"
    t.text "bibliography"
    t.string "author", limit: 255
    t.string "status", limit: 255
    t.string "common_name", limit: 255
    t.string "family_common_name", limit: 255
    t.string "scientific_name", limit: 255
    t.bigint "genus_id"
    t.datetime "inserted_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "main_species_id"
    t.boolean "complete_data"
    t.boolean "vegetable", default: false, null: false
    t.text "observations"
    t.integer "species_count"
    t.integer "completion_ratio"
    t.datetime "reviewed_at", precision: nil
    t.datetime "created_at", precision: nil
    t.integer "images_count", default: 0, null: false
    t.integer "sources_count", default: 0, null: false
    t.integer "main_species_gbif_score", default: 0, null: false
    t.string "main_image_url"
    t.index ["genus_id"], name: "plants_genus_id_index"
    t.index ["id", "main_species_id"], name: "plants_id_main_species_id_index", unique: true
    t.index ["main_species_gbif_score"], name: "plants_main_species_gbif_score_idx"
    t.index ["main_species_id"], name: "plants_main_species_id_index"
    t.index ["scientific_name"], name: "plants_scientific_name_index", unique: true
    t.index ["slug"], name: "index_plants_on_slug"
  end

  create_table "record_corrections", force: :cascade do |t|
    t.string "record_type"
    t.bigint "record_id"
    t.bigint "user_id"
    t.text "correction_json"
    t.string "warning_type"
    t.integer "change_status", default: 0, null: false
    t.integer "change_type", default: 0, null: false
    t.integer "accepted_by"
    t.text "notes"
    t.text "change_notes"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "source_type", default: 0, null: false
    t.string "source_reference"
    t.index ["record_type", "record_id"], name: "index_record_corrections_on_record_type_and_record_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.string "name", limit: 255
    t.datetime "started_at", precision: nil
    t.datetime "ended_at", precision: nil
    t.jsonb "counters"
    t.datetime "inserted_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "species", force: :cascade do |t|
    t.integer "year"
    t.text "bibliography"
    t.string "author", limit: 255
    t.string "scientific_name", limit: 255
    t.bigint "plant_id"
    t.string "slug", limit: 255
    t.datetime "inserted_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "fruit_conspicuous"
    t.float "ph_minimum"
    t.boolean "flower_conspicuous"
    t.float "frost_free_days_minimum"
    t.string "growth_habit", limit: 255
    t.string "protein_potential", limit: 255
    t.boolean "adapted_to_medium_textured_soils"
    t.string "growth_form", limit: 255
    t.string "nitrogen_fixation", limit: 255
    t.string "anaerobic_tolerance", limit: 255
    t.string "lifespan", limit: 255
    t.float "ph_maximum"
    t.string "shape_and_orientation", limit: 255
    t.boolean "adapted_to_fine_textured_soils"
    t.string "growth_rate", limit: 255
    t.boolean "fruit_seed_persistence"
    t.string "c_n_ratio", limit: 255
    t.boolean "leaf_retention"
    t.boolean "known_allelopath"
    t.boolean "adapted_to_coarse_textured_soils"
    t.string "caco_3_tolerance", limit: 255
    t.integer "genus_id"
    t.integer "main_species_id"
    t.string "family_common_name", limit: 255
    t.string "common_name", limit: 255
    t.boolean "complete_data"
    t.text "observations"
    t.boolean "vegetable"
    t.boolean "edible"
    t.datetime "reviewed_at", precision: nil
    t.datetime "created_at", precision: nil
    t.decimal "minimum_temperature_deg_f"
    t.decimal "minimum_temperature_deg_c"
    t.decimal "maximum_temperature_deg_f"
    t.decimal "maximum_temperature_deg_c"
    t.integer "rank"
    t.integer "sources_count", default: 0, null: false
    t.integer "images_count", default: 0, null: false
    t.integer "synonyms_count", default: 0, null: false
    t.integer "gbif_score", default: 0, null: false
    t.bigint "duration", default: 0, null: false
    t.bigint "propagated_by", default: 0, null: false
    t.bigint "growth_months", default: 0, null: false
    t.bigint "bloom_months", default: 0, null: false
    t.bigint "fruit_months", default: 0, null: false
    t.integer "status"
    t.integer "toxicity"
    t.integer "foliage_texture"
    t.string "inflorescence_raw"
    t.string "sexuality_raw"
    t.string "maturation_order"
    t.string "pollinisation_raw"
    t.string "fruit_shape_raw"
    t.string "dissemination_raw"
    t.integer "ligneous_type"
    t.bigint "flower_color", default: 0, null: false
    t.bigint "fruit_color", default: 0, null: false
    t.integer "light"
    t.integer "atmospheric_humidity"
    t.integer "ground_humidity"
    t.bigint "foliage_color", default: 0, null: false
    t.integer "soil_texture"
    t.integer "soil_salinity"
    t.integer "soil_nutriments"
    t.integer "hardiness_zone"
    t.integer "inflorescence_form"
    t.integer "inflorescence_type"
    t.integer "sexuality", default: 0, null: false
    t.string "maturation_order_raw"
    t.integer "pollinisation", default: 0, null: false
    t.integer "fruit_shape"
    t.integer "dissemination", default: 0, null: false
    t.integer "biological_type"
    t.string "biological_type_raw"
    t.datetime "checked_at", precision: nil
    t.text "token"
    t.text "full_token"
    t.integer "edible_part", default: 0, null: false
    t.text "planting_description"
    t.text "planting_sowing_description"
    t.integer "planting_days_to_harvest"
    t.integer "planting_row_spacing_cm"
    t.integer "planting_spread_cm"
    t.string "main_image_url"
    t.integer "maximum_height_cm"
    t.integer "maximum_precipitation_mm"
    t.integer "minimum_precipitation_mm"
    t.integer "minimum_root_depth_cm"
    t.string "genus_name"
    t.string "family_name"
    t.integer "average_height_cm"
    t.integer "completion_ratio"
    t.string "phylum"
    t.integer "wiki_score"
    t.index ["author"], name: "index_species_on_author"
    t.index ["average_height_cm"], name: "index_species_on_average_height_cm"
    t.index ["common_name"], name: "index_species_on_common_name"
    t.index ["family_common_name"], name: "index_species_on_family_common_name"
    t.index ["flower_conspicuous"], name: "index_species_on_flower_conspicuous"
    t.index ["gbif_score"], name: "species_gbif_score_idx"
    t.index ["genus_id"], name: "species_genus_id_index"
    t.index ["genus_name"], name: "index_species_on_genus_name"
    t.index ["light"], name: "index_species_on_light"
    t.index ["main_species_id", "common_name"], name: "index_species_on_main_species_id_and_common_name"
    t.index ["main_species_id", "gbif_score"], name: "index_species_on_main_species_id_and_gbif_score"
    t.index ["main_species_id"], name: "species_main_species_id_index"
    t.index ["maximum_height_cm"], name: "index_species_on_maximum_height_cm"
    t.index ["minimum_precipitation_mm"], name: "index_species_on_minimum_precipitation_mm"
    t.index ["minimum_root_depth_cm"], name: "index_species_on_minimum_root_depth_cm"
    t.index ["minimum_temperature_deg_f"], name: "index_species_on_minimum_temperature_deg_f"
    t.index ["plant_id"], name: "species_plant_id_index"
    t.index ["planting_days_to_harvest"], name: "index_species_on_planting_days_to_harvest"
    t.index ["planting_row_spacing_cm"], name: "index_species_on_planting_row_spacing_cm"
    t.index ["planting_spread_cm"], name: "index_species_on_planting_spread_cm"
    t.index ["scientific_name"], name: "species_scientific_name_index", unique: true
    t.index ["slug"], name: "index_species_on_slug"
    t.index ["token"], name: "index_species_on_token"
  end

  create_table "species_distributions", force: :cascade do |t|
    t.bigint "zone_id", null: false
    t.bigint "species_id", null: false
    t.integer "establishment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["species_id"], name: "index_species_distributions_on_species_id"
    t.index ["zone_id"], name: "index_species_distributions_on_zone_id"
  end

  create_table "species_images", force: :cascade do |t|
    t.string "image_url", limit: 255, null: false
    t.integer "species_id"
    t.datetime "inserted_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "image_type"
    t.text "copyright"
    t.datetime "created_at", precision: nil
    t.integer "part"
    t.integer "score", default: 0, null: false
    t.index ["image_url", "species_id"], name: "species_images_image_url_species_id_index", unique: true
    t.index ["species_id"], name: "index_species_images_on_species_id"
  end

  create_table "species_proposals", force: :cascade do |t|
    t.integer "year"
    t.string "bibliography", limit: 255
    t.string "author", limit: 255
    t.string "scientific_name", limit: 255
    t.string "status", limit: 255
    t.boolean "fruit_conspicuous", default: false, null: false
    t.boolean "coppice_potential", default: false, null: false
    t.string "fruit_seed_period_end", limit: 255
    t.boolean "resprout_ability", default: false, null: false
    t.boolean "propogated_by_sprigs", default: false, null: false
    t.boolean "propogated_by_cuttings", default: false, null: false
    t.boolean "fodder_product", default: false, null: false
    t.float "precipitation_minimum"
    t.string "toxicity", limit: 255
    t.string "foliage_texture", limit: 255
    t.string "fruit_seed_abundance", limit: 255
    t.boolean "fire_resistance", default: false, null: false
    t.float "height_at_base_age_max_ft"
    t.boolean "fall_conspicuous", default: false, null: false
    t.string "fire_tolerance", limit: 255
    t.float "ph_minimum"
    t.boolean "propogated_by_container", default: false, null: false
    t.boolean "flower_conspicuous", default: false, null: false
    t.string "native_status", limit: 255
    t.string "fuelwood_product", limit: 255
    t.float "frost_free_days_minimum"
    t.string "growth_habit", limit: 255
    t.string "protein_potential", limit: 255
    t.float "planting_density_per_acre_maximum"
    t.float "root_depth_minimum_inches"
    t.boolean "adapted_to_medium_textured_soils", default: false, null: false
    t.string "growth_form", limit: 255
    t.string "after_harvest_regrowth_rate", limit: 255
    t.string "drought_tolerance", limit: 255
    t.string "salinity_tolerance", limit: 255
    t.string "fertility_requirement", limit: 255
    t.string "foliage_color", limit: 255
    t.string "nitrogen_fixation", limit: 255
    t.string "commercial_availability", limit: 255
    t.string "anaerobic_tolerance", limit: 255
    t.string "lifespan", limit: 255
    t.boolean "veneer_product", default: false, null: false
    t.string "bloat", limit: 255
    t.float "precipitation_maximum"
    t.float "planting_density_per_acre_minimum"
    t.string "foliage_porosity_winter", limit: 255
    t.float "height_mature_ft"
    t.float "ph_maximum"
    t.boolean "christmas_tree_product", default: false, null: false
    t.string "shape_and_orientation", limit: 255
    t.string "shade_tolerance", limit: 255
    t.string "usda_synonym", limit: 255
    t.boolean "pulpwood_product", default: false, null: false
    t.boolean "small_grain", default: false, null: false
    t.boolean "low_growing_grass", default: false, null: false
    t.boolean "berry_nut_seed_product", default: false, null: false
    t.string "vegetative_spread_rate", limit: 255
    t.boolean "propogated_by_bare_root", default: false, null: false
    t.boolean "propogated_by_sod", default: false, null: false
    t.string "fruit_seed_period_begin", limit: 255
    t.string "palatable_browse_animal", limit: 255
    t.string "foliage_porosity_summer", limit: 255
    t.float "seeds_per_pound"
    t.boolean "adapted_to_fine_textured_soils", default: false, null: false
    t.string "hedge_tolerance", limit: 255
    t.boolean "post_product", default: false, null: false
    t.string "growth_rate", limit: 255
    t.boolean "propogated_by_seed", default: false, null: false
    t.string "fruit_color", limit: 255
    t.boolean "nursery_stock_product", default: false, null: false
    t.string "seedling_vigor", limit: 255
    t.boolean "cold_stratification_required", default: false, null: false
    t.string "palatable_graze_animal", limit: 255
    t.string "bloom_period", limit: 255
    t.boolean "fruit_seed_persistence", default: false, null: false
    t.boolean "propogated_by_bulbs", default: false, null: false
    t.string "active_growth_period", limit: 255
    t.string "c_n_ratio", limit: 255
    t.string "duration", limit: 255
    t.string "flower_color", limit: 255
    t.boolean "leaf_retention", default: false, null: false
    t.boolean "known_allelopath", default: false, null: false
    t.boolean "palatable_human", default: false, null: false
    t.boolean "propogated_by_tubers", default: false, null: false
    t.string "moisture_use", limit: 255
    t.boolean "lumber_product", default: false, null: false
    t.boolean "adapted_to_coarse_textured_soils", default: false, null: false
    t.boolean "propogated_by_corms", default: false, null: false
    t.float "temperature_minimum_deg_f"
    t.boolean "naval_store_product", default: false, null: false
    t.string "seed_spread_rate", limit: 255
    t.string "caco_3_tolerance", limit: 255
    t.string "species_type", limit: 255
    t.string "usda_name", limit: 255
    t.string "family_common_name", limit: 255
    t.string "common_name", limit: 255
    t.boolean "complete_data", default: false, null: false
    t.bigint "genus_id"
    t.bigint "user_id"
    t.datetime "inserted_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "change_type", limit: 255, null: false
    t.string "change_status", limit: 255, default: "pending", null: false
    t.integer "synonym_of_id"
  end

  create_table "species_trends", force: :cascade do |t|
    t.bigint "species_id", null: false
    t.bigint "foreign_source_id", null: false
    t.integer "score"
    t.datetime "date", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["foreign_source_id"], name: "index_species_trends_on_foreign_source_id"
    t.index ["species_id"], name: "index_species_trends_on_species_id"
  end

  create_table "subkingdoms", force: :cascade do |t|
    t.string "name", limit: 255
    t.string "slug", limit: 255
    t.bigint "kingdom_id"
    t.datetime "inserted_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "created_at", precision: nil
    t.index ["name"], name: "subkingdoms_name_index", unique: true
    t.index ["slug"], name: "subkingdoms_slug_index", unique: true
  end

  create_table "synonyms", force: :cascade do |t|
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.string "name"
    t.string "author"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_synonyms_on_name"
    t.index ["record_type", "record_id"], name: "index_synonyms_on_record_type_and_record_id"
  end

  create_table "user_queries", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "controller"
    t.string "action"
    t.bigint "counter"
    t.integer "time"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_user_queries_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", limit: 255
    t.string "email", limit: 255
    t.string "password_hash", limit: 255
    t.string "reset_password_token", limit: 255
    t.datetime "reset_password_sent_at", precision: nil
    t.integer "failed_attempts", default: 0
    t.datetime "locked_at", precision: nil
    t.integer "sign_in_count", default: 0
    t.datetime "current_sign_in_at", precision: nil
    t.datetime "last_sign_in_at", precision: nil
    t.string "current_sign_in_ip", limit: 255
    t.string "last_sign_in_ip", limit: 255
    t.string "unlock_token", limit: 255
    t.string "confirmation_token", limit: 255
    t.datetime "confirmed_at", precision: nil
    t.datetime "confirmation_sent_at", precision: nil
    t.datetime "inserted_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "admin", default: false
    t.string "token", limit: 255
    t.string "organization_name", limit: 255
    t.string "organization_url", limit: 255
    t.string "organization_image_url", limit: 255
    t.string "account_type", limit: 255
    t.boolean "public_profile"
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at", precision: nil
    t.string "unconfirmed_email"
    t.datetime "created_at", precision: nil
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["email"], name: "users_email_index", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "zones", force: :cascade do |t|
    t.string "name", null: false
    t.string "feature"
    t.string "tdwg_code"
    t.integer "tdwg_level"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "slug"
    t.integer "species_count", default: 0, null: false
    t.integer "parent_id"
  end

  add_foreign_key "division_classes", "divisions", name: "division_classes_division_id_fkey"
  add_foreign_key "division_orders", "division_classes", name: "division_orders_division_class_id_fkey"
  add_foreign_key "divisions", "subkingdoms", name: "divisions_subkingdom_id_fkey"
  add_foreign_key "families", "division_orders", name: "families_division_order_id_fkey"
  add_foreign_key "families", "major_groups", name: "families_major_group_id_fkey"
  add_foreign_key "foreign_sources_plants", "foreign_sources", name: "foreign_sources_plants_foreign_source_id_fkey"
  add_foreign_key "foreign_sources_plants", "species", name: "foreign_sources_plants_species_id_fkey"
  add_foreign_key "genuses", "families", name: "genuses_family_id_fkey"
  add_foreign_key "plants", "genuses", column: "genus_id", name: "plants_genus_id_fkey"
  add_foreign_key "record_corrections", "users"
  add_foreign_key "species", "plants", name: "species_plant_id_fkey"
  add_foreign_key "species_distributions", "species"
  add_foreign_key "species_distributions", "zones"
  add_foreign_key "species_proposals", "genuses", column: "genus_id", name: "species_proposals_genus_id_fkey"
  add_foreign_key "species_proposals", "users", name: "species_proposals_user_id_fkey"
  add_foreign_key "species_trends", "foreign_sources"
  add_foreign_key "species_trends", "species"
  add_foreign_key "subkingdoms", "kingdoms", name: "subkingdoms_kingdom_id_fkey"
  add_foreign_key "user_queries", "users"
end
