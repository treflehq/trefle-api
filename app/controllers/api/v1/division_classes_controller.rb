class Api::V1::DivisionClassesController < Api::ApiController

  def index
    @collection = DivisionClass.all.preload(
      division: { subkingdom: :kingdom }
    )
    @collection = @collection.order(created_at: :asc)
    @pagy, @collection = pagy(@collection)

    links = collection_links(@collection, name: :division_classes)

    render_serialized_collection(
      @collection,
      DivisionClassSerializer,
      links: links
    )
  end

  def show
    @resource = DivisionClass.friendly.find(params[:id])

    render_serialized_resource(
      @resource,
      DivisionClassSerializer,
      meta: resource_metadata(@resource)
    )
  end
end
