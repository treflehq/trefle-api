class Api::V1::ZonesController < Api::ApiController

  ORDERABLE_FIELDS = %w[name slug species_count tdwg_level tdwg_code].freeze
  FILTERABLE_FIELDS = %w[tdwg_level tdwg_code].freeze
  RANGEABLE_FIELDS = %w[tdwg_level species_count].freeze

  def index
    @collection = collection

    links = collection_links(@collection, name: :zones)

    render_serialized_collection(
      @collection,
      ZoneSerializer,
      links: links
    )
  end

  def show
    @resource = Zone.friendly.find(params[:id])

    render_serialized_resource(
      @resource,
      ZoneSerializer,
      meta: resource_metadata(@resource)
    )
  end

  def collection
    return @collection if @collection

    @collection = Zone.all

    @collection = apply_filters(@collection, FILTERABLE_FIELDS)
    @collection = apply_sort(@collection, ORDERABLE_FIELDS, default_sort: { name: :asc })
    @collection = apply_range(@collection, RANGEABLE_FIELDS)
    @collection = apply_search(collection)

    @pagy, @collection = pagy(@collection)
    @collection
  end

end
