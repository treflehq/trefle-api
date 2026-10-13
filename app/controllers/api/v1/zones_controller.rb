class Api::V1::ZonesController < Api::ApiController

  ORDERABLE_FIELDS = %w[name slug species_count species_count_cumulative tdwg_level tdwg_code].freeze
  FILTERABLE_FIELDS = %w[tdwg_level tdwg_code].freeze
  RANGEABLE_FIELDS = %w[tdwg_level species_count species_count_cumulative].freeze

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
    @resource = Zone.resolve!(params[:id])

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
    # Before the sort: `?q=` ranks exact name matches first, the requested
    # (or default) order only breaks ties.
    @collection = apply_search(@collection)
    @collection = apply_sort(@collection, ORDERABLE_FIELDS, default_sort: { name: :asc })
    @collection = apply_range(@collection, RANGEABLE_FIELDS)

    @pagy, @collection = pagy(@collection)
    @collection
  end

end
