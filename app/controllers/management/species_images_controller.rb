class Management::SpeciesImagesController < Management::ManagementController
  before_action :set_species_image, only: %i[show edit update destroy]

  # GET /species_images
  # GET /species_images.json
  def index
    @species_images = SpeciesImage.all
    @pagy, @species_images = pagy(@species_images)
  end

  # GET /species_images/chaos
  # GET /species_images/chaos.json
  def chaos
    @species_images = SpeciesImage.all
      .includes(:species)
      .order(updated_at: :asc)
    @pagy, @species_images = pagy(@species_images)
  end

  # GET /species_images/1
  # GET /species_images/1.json
  def show; end

  # GET /species_images/new
  def new
    @species_image = SpeciesImage.new
  end

  # GET /species_images/1/edit
  def edit; end

  # POST /species_images
  # POST /species_images.json
  def create
    @species_image = SpeciesImage.new(species_image_params)

    respond_to do |format|
      if @species_image.save
        format.html { redirect_to @species_image, notice: 'Species image was successfully created.' }
        format.json { render :show, status: :created, location: @species_image }
      else
        format.html { render :new }
        format.json { render json: @species_image.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /species_images/1
  # PATCH/PUT /species_images/1.json
  def update
    respond_to do |format|
      if @species_image.update(species_image_params)
        format.html { redirect_to @species_image, notice: 'Species image was successfully updated.' }
        format.json { render :show, status: :ok, location: @species_image }
      else
        format.html { render :edit }
        format.json { render json: @species_image.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /species_images/1
  # DELETE /species_images/1.json
  def destroy
    @species_image.destroy
    respond_to do |format|
      format.html { redirect_to chaos_management_species_images_url, notice: 'Species image was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_species_image
    @species_image = SpeciesImage.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def species_image_params
    params.require(:species_image).permit(:image_url, :species_id, :inserted_at)
  end
end
