class Api::V1::FamiliesController < Api::ApiController
  FILTERABLE_FIELDS = %w[name slug].freeze
  ORDERABLE_FIELDS = %w[name slug].freeze

  def index
    @collection = collection

    links = collection_links(@collection, name: :families)

    render_serialized_collection(
      @collection,
      FamilySerializer,
      links: links
    )
  end

  def show
    @resource = Family.friendly.find(params[:id])

    render_serialized_resource(
      @resource,
      FamilySerializer,
      meta: resource_metadata(@resource)
    )
  end

  def collection
    return @collection if @collection

    @collection ||= Family.all.preload(
      division_order: { division_class: { division: { subkingdom: :kingdom } } }
    )

    @collection = apply_filters(@collection, FILTERABLE_FIELDS)
    @collection = apply_sort(@collection, ORDERABLE_FIELDS, default_sort: { name: :asc })
    # @collection = apply_search(collection)

    @pagy, @collection = pagy(@collection)
    @collection
  end

end
