class Management::DivisionOrdersController < Management::ManagementController
  before_action :set_division_order, only: %i[show edit update destroy]

  # GET /division_orders
  # GET /division_orders.json
  def index
    @division_orders = DivisionOrder.all.page params[:page]
  end

  # GET /division_orders/1
  # GET /division_orders/1.json
  def show; end

  # GET /division_orders/new
  def new
    @division_order = DivisionOrder.new
  end

  # GET /division_orders/1/edit
  def edit; end

  # POST /division_orders
  # POST /division_orders.json
  def create
    @division_order = DivisionOrder.new(division_order_params)

    respond_to do |format|
      if @division_order.save
        format.html { redirect_to @division_order, notice: 'Division order was successfully created.' }
        format.json { render :show, status: :created, location: @division_order }
      else
        format.html { render :new }
        format.json { render json: @division_order.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /division_orders/1
  # PATCH/PUT /division_orders/1.json
  def update
    respond_to do |format|
      if @division_order.update(division_order_params)
        format.html { redirect_to @division_order, notice: 'Division order was successfully updated.' }
        format.json { render :show, status: :ok, location: @division_order }
      else
        format.html { render :edit }
        format.json { render json: @division_order.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /division_orders/1
  # DELETE /division_orders/1.json
  def destroy
    @division_order.destroy
    respond_to do |format|
      format.html { redirect_to division_orders_url, notice: 'Division order was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_division_order
    @division_order = DivisionOrder.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def division_order_params
    params.require(:division_order).permit(:name, :slug, :division_class_id, :inserted_at)
  end
end
