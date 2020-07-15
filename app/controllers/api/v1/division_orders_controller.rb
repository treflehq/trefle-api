class Api::V1::DivisionOrdersController < Api::ApiController

  def index
    @collection = DivisionOrder.all.preload(
      division_class: { division: { subkingdom: :kingdom } }
    )
    @collection = @collection.order(created_at: :asc)
    @pagy, @collection = pagy(@collection)

    links = collection_links(@collection, name: :division_orders)

    render_serialized_collection(
      @collection,
      DivisionOrderSerializer,
      links: links
    )
  end

  def show
    @resource = DivisionOrder.friendly.find(params[:id])

    render_serialized_resource(
      @resource,
      DivisionOrderSerializer,
      meta: resource_metadata(@resource)
    )
  end

end
