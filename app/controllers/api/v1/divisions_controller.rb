class Api::V1::DivisionsController < Api::ApiController

  def index
    @collection = Division.all.preload({ subkingdom: :kingdom })
    @collection = @collection.order(created_at: :asc)
    @pagy, @collection = pagy(@collection)

    links = collection_links(@collection, name: :divisions)

    render_serialized_collection(
      @collection,
      DivisionSerializer,
      links: links
    )
  end

  def show
    @resource = Division.friendly.find(params[:id])

    render_serialized_resource(
      @resource,
      DivisionSerializer,
      meta: resource_metadata(@resource)
    )
  end

end
