class Management::MajorGroupsController < Management::ManagementController
  before_action :set_major_group, only: %i[show edit update destroy]

  # GET /major_groups
  # GET /major_groups.json
  def index
    @major_groups = MajorGroup.all
    @pagy, @major_groups = pagy(@major_groups)
  end

  # GET /major_groups/1
  # GET /major_groups/1.json
  def show; end

  # GET /major_groups/new
  def new
    @major_group = MajorGroup.new
  end

  # GET /major_groups/1/edit
  def edit; end

  # POST /major_groups
  # POST /major_groups.json
  def create
    @major_group = MajorGroup.new(major_group_params)

    respond_to do |format|
      if @major_group.save
        format.html { redirect_to @major_group, notice: 'Major group was successfully created.' }
        format.json { render :show, status: :created, location: @major_group }
      else
        format.html { render :new }
        format.json { render json: @major_group.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /major_groups/1
  # PATCH/PUT /major_groups/1.json
  def update
    respond_to do |format|
      if @major_group.update(major_group_params)
        format.html { redirect_to @major_group, notice: 'Major group was successfully updated.' }
        format.json { render :show, status: :ok, location: @major_group }
      else
        format.html { render :edit }
        format.json { render json: @major_group.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /major_groups/1
  # DELETE /major_groups/1.json
  def destroy
    @major_group.destroy
    respond_to do |format|
      format.html { redirect_to major_groups_url, notice: 'Major group was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_major_group
    @major_group = MajorGroup.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def major_group_params
    params.require(:major_group).permit(:name, :slug, :inserted_at)
  end
end
