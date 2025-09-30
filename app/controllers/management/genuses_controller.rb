class Management::GenusesController < Management::ManagementController
  before_action :set_genuse, only: %i[show edit update destroy]

  # GET /genuses
  # GET /genuses.json
  def index
    @genuses = Genus.all
    @pagy, @genuses = pagy(@genuses)
  end

  # GET /genuses/1
  # GET /genuses/1.json
  def show; end

  # GET /genuses/new
  def new
    @genuse = Genus.new
  end

  # GET /genuses/1/edit
  def edit; end

  # POST /genuses
  # POST /genuses.json
  def create
    @genuse = Genus.new(genuse_params)

    respond_to do |format|
      if @genuse.save
        format.html { redirect_to @genuse, notice: 'Genus was successfully created.' }
        format.json { render :show, status: :created, location: @genuse }
      else
        format.html { render :new }
        format.json { render json: @genuse.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /genuses/1
  # PATCH/PUT /genuses/1.json
  def update
    respond_to do |format|
      if @genuse.update(genuse_params)
        format.html { redirect_to @genuse, notice: 'Genus was successfully updated.' }
        format.json { render :show, status: :ok, location: @genuse }
      else
        format.html { render :edit }
        format.json { render json: @genuse.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /genuses/1
  # DELETE /genuses/1.json
  def destroy
    @genuse.destroy
    respond_to do |format|
      format.html { redirect_to genuses_url, notice: 'Genus was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_genuse
    @genuse = Genus.friendly.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def genuse_params
    params.require(:genuse).permit(:name, :slug, :family_id, :inserted_at)
  end
end
