class Management::ForeignSourcesPlantsController < Management::ManagementController
  before_action :set_foreign_sources_plant, only: %i[show edit update destroy]

  # GET /foreign_sources_plants
  # GET /foreign_sources_plants.json
  def index
    @foreign_sources_plants = ForeignSourcesPlant.all
    @pagy, @foreign_sources_plants = pagy(@foreign_sources_plants)
  end

  # GET /foreign_sources_plants/1
  # GET /foreign_sources_plants/1.json
  def show; end

  # GET /foreign_sources_plants/new
  def new
    @foreign_sources_plant = ForeignSourcesPlant.new
  end

  # GET /foreign_sources_plants/1/edit
  def edit; end

  # POST /foreign_sources_plants
  # POST /foreign_sources_plants.json
  def create
    @foreign_sources_plant = ForeignSourcesPlant.new(foreign_sources_plant_params)

    respond_to do |format|
      if @foreign_sources_plant.save
        format.html { redirect_to @foreign_sources_plant, notice: 'Foreign sources plant was successfully created.' }
        format.json { render :show, status: :created, location: @foreign_sources_plant }
      else
        format.html { render :new }
        format.json { render json: @foreign_sources_plant.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /foreign_sources_plants/1
  # PATCH/PUT /foreign_sources_plants/1.json
  def update
    respond_to do |format|
      if @foreign_sources_plant.update(foreign_sources_plant_params)
        format.html { redirect_to @foreign_sources_plant, notice: 'Foreign sources plant was successfully updated.' }
        format.json { render :show, status: :ok, location: @foreign_sources_plant }
      else
        format.html { render :edit }
        format.json { render json: @foreign_sources_plant.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /foreign_sources_plants/1
  # DELETE /foreign_sources_plants/1.json
  def destroy
    @foreign_sources_plant.destroy
    respond_to do |format|
      format.html { redirect_to foreign_sources_plants_url, notice: 'Foreign sources plant was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_foreign_sources_plant
    @foreign_sources_plant = ForeignSourcesPlant.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def foreign_sources_plant_params
    params.require(:foreign_sources_plant).permit(:last_update, :species_id, :foreign_source_id, :fid, :inserted_at)
  end
end
