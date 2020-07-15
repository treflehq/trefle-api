class Api::V1::KingdomsController < Api::ApiController

  def index
    @collection = Kingdom.all
    @collection = @collection.order(created_at: :asc)
    @pagy, @collection = pagy(@collection)

    links = collection_links(@collection, name: :kingdoms)

    render_serialized_collection(
      @collection,
      KingdomSerializer,
      links: links
    )
  end

  def show
    @resource = Kingdom.friendly.find(params[:id])

    render_serialized_resource(
      @resource,
      KingdomSerializer,
      meta: resource_metadata(@resource)
    )
  end

end
