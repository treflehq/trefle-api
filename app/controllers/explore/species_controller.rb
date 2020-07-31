class Explore::SpeciesController < Explore::ExploreController
  before_action :set_species, only: %i[show edit update destroy refresh]

  has_scope :vegetable, type: :boolean, allow_blank: true
  has_scope :edible, type: :boolean, allow_blank: true

  # GET /species
  # GET /species.json
  def index
    search = params[:search]


    unless search.blank?
      options = {
        includes: %i[synonyms genus plant],
        boost_by: [:gbif_score],
        fields: ['common_name^10', 'common_names^8', 'scientific_name^5', 'synonyms^3', 'author', 'genus', 'family', 'family_common_name', 'distributions']
      }.compact

      @collection = Species.pagy_search(search, options)
      @pagy, @collection = pagy_searchkick(@collection, items: (params[:limit] || 20).to_i)
    else
      @collection ||= Species.all.preload(:plant, :genus, :synonyms).order(gbif_score: :desc)
      @pagy, @collection = pagy(@collection)
    end
  end

  # GET /species/1
  # GET /species/1.json
  def show
    
  end

  # # GET /species/new
  # def new
  #   @species = Species.new
  # end

  # # GET /species/1/edit
  # def edit; end

  # # POST /species
  # # POST /species.json
  # def create
  #   @species = Species.new(species_params)

  #   respond_to do |format|
  #     if @species.save
  #       format.html { redirect_to [:management, @species], notice: 'Species was successfully created.' }
  #       format.json { render :show, status: :created, location: @species }
  #     else
  #       format.html { render :new }
  #       format.json { render json: @species.errors, status: :unprocessable_entity }
  #     end
  #   end
  # end

  # # PATCH/PUT /species/1
  # # PATCH/PUT /species/1.json
  # def update
  #   respond_to do |format|
  #     if @species.update(species_params)
  #       @species.update(reviewed_at: Time.zone.now)
  #       format.html { redirect_to [:management, @species], notice: 'Species was successfully updated.' }
  #       format.json { render :show, status: :ok, location: @species }
  #     else
  #       format.html { render :edit }
  #       format.json { render json: @species.errors, status: :unprocessable_entity }
  #     end
  #   end
  # end

  # # DELETE /species/1
  # # DELETE /species/1.json
  # def destroy
  #   @species.destroy
  #   respond_to do |format|
  #     format.html { redirect_to species_index_url, notice: 'Species was successfully destroyed.' }
  #     format.json { head :no_content }
  #   end
  # end

  # def refresh
  #   respond_to do |format|
  #     if @species
  #       Crawlers::SpeciesFetchWorker.perform_async(@species.slug)
  #       format.html { redirect_to [:management, @species], notice: 'Species refresh enqueued.' }
  #       format.json { render :show, status: :ok, location: @species }
  #     else
  #       format.html { redirect_to [:management, @species], notice: 'En error occured' }
  #       format.json { render json: @species.errors, status: :unprocessable_entity }
  #     end
  #   end
  # end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_species
    @species = Species.friendly.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def species_params # rubocop:todo Metrics/MethodLength
    params.require(:species).permit(
      :adapted_to_coarse_textured_soils,
      :adapted_to_fine_textured_soils,
      :adapted_to_medium_textured_soils,
      :anaerobic_tolerance,
      :atmospheric_humidity,
      :author,
      :bibliography,
      :biological_type,
      :biological_type_raw,
      :c_n_ratio,
      :caco_3_tolerance,
      :checked_at,
      :common_name,
      :complete_data,
      :dissemination,
      :dissemination_raw,
      :edible,
      :edible_part,
      :family_common_name,
      :flower_conspicuous,
      :foliage_texture,
      :frost_free_days_minimum,
      :fruit_conspicuous,
      :fruit_seed_persistence,
      :fruit_shape,
      :fruit_shape_raw,
      :full_token,
      :gbif_score,
      :ground_humidity,
      :growth_form,
      :growth_habit,
      :growth_rate,
      :hardiness_zone,
      :images_count,
      :inflorescence_form,
      :inflorescence_raw,
      :inflorescence_type,
      :inserted_at,
      :known_allelopath,
      :leaf_retention,
      :lifespan,
      :light,
      :ligneous_type,
      :maturation_order,
      :maturation_order_raw,
      :average_height_cm,
      :maximum_height_cm,
      :minimum_precipitation_mm,
      :maximum_precipitation_mm,
      :minimum_root_depth_cm,
      :maximum_temperature_deg_c,
      :maximum_temperature_deg_f,
      :minimum_temperature_deg_c,
      :minimum_temperature_deg_f,
      :nitrogen_fixation,
      :observations,
      :ph_maximum,
      :ph_minimum,
      :planting_days_to_harvest,
      :planting_description,
      :planting_row_spacing_cm,
      :planting_sowing_description,
      :planting_spread_cm,
      :pollinisation,
      :pollinisation_raw,
      :protein_potential,
      :rank,
      :reviewed_at,
      :scientific_name,
      :sexuality,
      :sexuality_raw,
      :shape_and_orientation,
      :slug,
      :soil_nutriments,
      :soil_salinity,
      :soil_texture,
      :sources_count,
      :status,
      :synonyms_count,
      :token,
      :toxicity,
      :vegetable,
      :year,
      :z_leg_after_harvest_regrowth_rate,
      :z_leg_berry_nut_seed_product,
      :z_leg_bloat,
      :z_leg_christmas_tree_product,
      :z_leg_cold_stratification_required,
      :z_leg_commercial_availability,
      :z_leg_coppice_potential,
      :z_leg_drought_tolerance,
      :z_leg_fall_conspicuous,
      :z_leg_fertility_requirement,
      :z_leg_fire_resistance,
      :z_leg_fire_tolerance,
      :z_leg_fodder_product,
      :z_leg_foliage_porosity_summer,
      :z_leg_foliage_porosity_winter,
      :z_leg_fruit_seed_abundance,
      :z_leg_fuelwood_product,
      :z_leg_hedge_tolerance,
      :z_leg_low_growing_grass,
      :z_leg_lumber_product,
      :z_leg_moisture_use,
      :z_leg_native_status,
      :z_leg_naval_store_product,
      :z_leg_nursery_stock_product,
      :z_leg_palatable_browse_animal,
      :z_leg_palatable_graze_animal,
      :z_leg_palatable_human,
      :z_leg_post_product,
      :z_leg_pulpwood_product,
      :z_leg_resprout_ability,
      :z_leg_salinity_tolerance,
      :z_leg_seed_spread_rate,
      :z_leg_seedling_vigor,
      :z_leg_seeds_per_pound,
      :z_leg_shade_tolerance,
      :z_leg_small_grain,
      :z_leg_usda_name,
      :z_leg_usda_synonym,
      :z_leg_vegetative_spread_rate,
      :z_leg_veneer_product,
      :created_at,
      :updated_at,
      :genus_id,
      :main_species_id,
      :plant_id,
      :synonym_of_id,
      bloom_months: [],
      fruit_months: [],
      growth_months: [],
      duration: [],
      propagated_by: [],
      flower_color: [],
      fruit_color: [],
      foliage_color: [],
      edible_part: []
    )
  end

end
