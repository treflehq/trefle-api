class Management::RecordCorrectionsController < Management::ManagementController

  before_action :set_record_correction, only: %i[show edit update destroy]

  # GET /record_corrections
  # GET /record_corrections.json
  def index
    p = params.permit(:search, order: {})

    @record_corrections = RecordCorrection.all
    @record_corrections = @record_corrections.order(p.to_h.dig('order')) if p[:order]
    # @record_corrections = @record_corrections.where.like(scientific_name: "%#{p[:search]}%") if p[:search]
    @pagy, @record_corrections = pagy(@record_corrections)
  end

  # GET /record_corrections/1
  # GET /record_corrections/1.json
  def show; end

  # GET /record_corrections/new
  def new
    @record_correction = RecordCorrection.new
  end

  # GET /record_corrections/1/edit
  def edit; end

  # POST /record_corrections
  # POST /record_corrections.json
  def create
    @record_correction = RecordCorrection.new(record_correction_params)

    respond_to do |format|
      if @record_correction.save
        format.html { redirect_to @record_correction, notice: 'RecordCorrection was successfully created.' }
        format.json { render :show, status: :created, location: @record_correction }
      else
        format.html { render :new }
        format.json { render json: @record_correction.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /record_corrections/1
  # PATCH/PUT /record_corrections/1.json
  def update
    respond_to do |format|
      if @record_correction.update(record_correction_params)
        format.html { redirect_to @record_correction, notice: 'RecordCorrection was successfully updated.' }
        format.json { render :show, status: :ok, location: @record_correction }
      else
        format.html { render :edit }
        format.json { render json: @record_correction.errors, status: :unprocessable_entity }
      end
    end
  end

  def accept
    # TODO
  end

  # DELETE /record_corrections/1
  # DELETE /record_corrections/1.json
  def destroy
    @record_correction.destroy
    respond_to do |format|
      format.html { redirect_to record_corrections_url, notice: 'RecordCorrection was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_record_correction
    @record_correction = RecordCorrection.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def record_correction_params
    params.require(:record_correction)
      .permit(:name, :slug, :kingdom_id, :inserted_at)
  end
end
