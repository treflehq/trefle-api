class Management::SubkingdomsController < Management::ManagementController
  before_action :set_subkingdom, only: %i[show edit update destroy]

  # GET /subkingdoms
  # GET /subkingdoms.json
  def index
    @subkingdoms = Subkingdom.all.page params[:page]
  end

  # GET /subkingdoms/1
  # GET /subkingdoms/1.json
  def show; end

  # GET /subkingdoms/new
  def new
    @subkingdom = Subkingdom.new
  end

  # GET /subkingdoms/1/edit
  def edit; end

  # POST /subkingdoms
  # POST /subkingdoms.json
  def create
    @subkingdom = Subkingdom.new(subkingdom_params)

    respond_to do |format|
      if @subkingdom.save
        format.html { redirect_to @subkingdom, notice: 'Subkingdom was successfully created.' }
        format.json { render :show, status: :created, location: @subkingdom }
      else
        format.html { render :new }
        format.json { render json: @subkingdom.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /subkingdoms/1
  # PATCH/PUT /subkingdoms/1.json
  def update
    respond_to do |format|
      if @subkingdom.update(subkingdom_params)
        format.html { redirect_to @subkingdom, notice: 'Subkingdom was successfully updated.' }
        format.json { render :show, status: :ok, location: @subkingdom }
      else
        format.html { render :edit }
        format.json { render json: @subkingdom.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /subkingdoms/1
  # DELETE /subkingdoms/1.json
  def destroy
    @subkingdom.destroy
    respond_to do |format|
      format.html { redirect_to subkingdoms_url, notice: 'Subkingdom was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_subkingdom
    @subkingdom = Subkingdom.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def subkingdom_params
    params.require(:subkingdom).permit(:name, :slug, :kingdom_id, :inserted_at)
  end
end
