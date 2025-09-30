class Management::KingdomsController < Management::ManagementController
  before_action :set_kingdom, only: %i[show edit update destroy]

  # GET /kingdoms
  # GET /kingdoms.json
  def index
    @kingdoms = Kingdom.all
  end

  # GET /kingdoms/1
  # GET /kingdoms/1.json
  def show; end

  # GET /kingdoms/new
  def new
    @kingdom = Kingdom.new
  end

  # GET /kingdoms/1/edit
  def edit; end

  # POST /kingdoms
  # POST /kingdoms.json
  def create
    @kingdom = Kingdom.new(kingdom_params)

    respond_to do |format|
      if @kingdom.save
        format.html { redirect_to @kingdom, notice: 'Kingdom was successfully created.' }
        format.json { render :show, status: :created, location: @kingdom }
      else
        format.html { render :new }
        format.json { render json: @kingdom.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /kingdoms/1
  # PATCH/PUT /kingdoms/1.json
  def update
    respond_to do |format|
      if @kingdom.update(kingdom_params)
        format.html { redirect_to @kingdom, notice: 'Kingdom was successfully updated.' }
        format.json { render :show, status: :ok, location: @kingdom }
      else
        format.html { render :edit }
        format.json { render json: @kingdom.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /kingdoms/1
  # DELETE /kingdoms/1.json
  def destroy
    @kingdom.destroy
    respond_to do |format|
      format.html { redirect_to kingdoms_url, notice: 'Kingdom was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_kingdom
    @kingdom = Kingdom.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def kingdom_params
    params.require(:kingdom).permit(:name, :slug, :inserted_at)
  end
end
