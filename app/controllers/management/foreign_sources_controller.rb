class Management::ForeignSourcesController < Management::ManagementController
  before_action :set_foreign_source, only: %i[show edit update destroy]

  # GET /foreign_sources
  # GET /foreign_sources.json
  def index
    @foreign_sources = ForeignSource.all
    @pagy, @foreign_sources = pagy(@foreign_sources)
  end

  # GET /foreign_sources/1
  # GET /foreign_sources/1.json
  def show; end

  # GET /foreign_sources/new
  def new
    @foreign_source = ForeignSource.new
  end

  # GET /foreign_sources/1/edit
  def edit; end

  # POST /foreign_sources
  # POST /foreign_sources.json
  def create
    @foreign_source = ForeignSource.new(foreign_source_params)

    respond_to do |format|
      if @foreign_source.save
        format.html { redirect_to @foreign_source, notice: 'Foreign source was successfully created.' }
        format.json { render :show, status: :created, location: @foreign_source }
      else
        format.html { render :new }
        format.json { render json: @foreign_source.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /foreign_sources/1
  # PATCH/PUT /foreign_sources/1.json
  def update
    respond_to do |format|
      if @foreign_source.update(foreign_source_params)
        format.html { redirect_to @foreign_source, notice: 'Foreign source was successfully updated.' }
        format.json { render :show, status: :ok, location: @foreign_source }
      else
        format.html { render :edit }
        format.json { render json: @foreign_source.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /foreign_sources/1
  # DELETE /foreign_sources/1.json
  def destroy
    @foreign_source.destroy
    respond_to do |format|
      format.html { redirect_to foreign_sources_url, notice: 'Foreign source was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_foreign_source
    @foreign_source = ForeignSource.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def foreign_source_params
    params.require(:foreign_source).permit(:name, :slug, :url, :inserted_at)
  end
end
