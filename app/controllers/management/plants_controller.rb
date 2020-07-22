class Management::PlantsController < Management::ManagementController
  before_action :set_plant, only: %i[show edit update destroy]

  # GET /plants
  # GET /plants.json
  def index
    p = params.permit(:search, order: {})
    @plants = Plant.all
    @plants = @plants.order(p.to_h.dig('order')) if p[:order]
    @plants = @plants.database_search(p[:search]) if p[:search]
    @pagy, @plants = pagy(@plants)
  end

  # GET /plants/1
  # GET /plants/1.json
  def show; end

  # GET /plants/new
  def new
    @plant = Plant.new
  end

  # GET /plants/1/edit
  def edit; end

  # POST /plants
  # POST /plants.json
  def create
    @plant = Plant.new(plant_params)

    respond_to do |format|
      if @plant.save
        format.html { redirect_to @plant, notice: 'Plant was successfully created.' }
        format.json { render :show, status: :created, location: @plant }
      else
        format.html { render :new }
        format.json { render json: @plant.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /plants/1
  # PATCH/PUT /plants/1.json
  def update
    respond_to do |format|
      if @plant.update(plant_params)
        format.html { redirect_to @plant, notice: 'Plant was successfully updated.' }
        format.json { render :show, status: :ok, location: @plant }
      else
        format.html { render :edit }
        format.json { render json: @plant.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /plants/1
  # DELETE /plants/1.json
  def destroy
    @plant.destroy
    respond_to do |format|
      format.html { redirect_to plants_url, notice: 'Plant was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_plant
    @plant = Plant.friendly.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def plant_params
    params.require(:plant).permit(:slug, :year, :bibliography, :author, :status, :common_name, :family_common_name, :scientific_name, :genus_id, :inserted_at, :main_species_id, :complete_data)
  end
end
