class Api::V1::SubkingdomsController < Api::ApiController

  def index
    @collection = Subkingdom.all
    @collection = @collection.order(created_at: :asc)
    @pagy, @collection = pagy(@collection)

    links = collection_links(@collection, name: :subkingdoms)

    render_serialized_collection(
      @collection,
      SubkingdomSerializer,
      links: links
    )
  end

  def show
    @resource = Subkingdom.friendly.find(params[:id])

    render_serialized_resource(
      @resource,
      SubkingdomSerializer,
      meta: resource_metadata(@resource)
    )
  end

end
