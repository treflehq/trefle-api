class Management::DivisionClassesController < Management::ManagementController
  before_action :set_division_class, only: %i[show edit update destroy]

  # GET /division_classes
  # GET /division_classes.json
  def index
    @division_classes = DivisionClass.all.page params[:page]
  end

  # GET /division_classes/1
  # GET /division_classes/1.json
  def show; end

  # GET /division_classes/new
  def new
    @division_class = DivisionClass.new
  end

  # GET /division_classes/1/edit
  def edit; end

  # POST /division_classes
  # POST /division_classes.json
  def create
    @division_class = DivisionClass.new(division_class_params)

    respond_to do |format|
      if @division_class.save
        format.html { redirect_to @division_class, notice: 'Division class was successfully created.' }
        format.json { render :show, status: :created, location: @division_class }
      else
        format.html { render :new }
        format.json { render json: @division_class.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /division_classes/1
  # PATCH/PUT /division_classes/1.json
  def update
    respond_to do |format|
      if @division_class.update(division_class_params)
        format.html { redirect_to @division_class, notice: 'Division class was successfully updated.' }
        format.json { render :show, status: :ok, location: @division_class }
      else
        format.html { render :edit }
        format.json { render json: @division_class.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /division_classes/1
  # DELETE /division_classes/1.json
  def destroy
    @division_class.destroy
    respond_to do |format|
      format.html { redirect_to division_classes_url, notice: 'Division class was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_division_class
    @division_class = DivisionClass.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def division_class_params
    params.require(:division_class).permit(:name, :slug, :division_id, :inserted_at)
  end
end
