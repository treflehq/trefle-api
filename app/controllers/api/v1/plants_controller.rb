class Api::V1::PlantsController < Api::ApiController

  include WithCachedCount

  # FILTERABLE_FIELDS = %w[
  #   author
  #   common_name
  #   complete
  #   family_common_name
  #   scientific_name
  #   vegetable
  #   year
  # ].freeze

  # ORDERABLE_FIELDS = %w[
  #   author
  #   common_name
  #   complete
  #   family_common_name
  #   scientific_name
  #   vegetable
  #   year
  #   species_count
  #   images_count
  # ].freeze

  # RANGEABLE_FIELDS = %w[
  #   year
  #   species_count
  #   images_count
  # ].freeze

  def index
    @collection = collection

    links = collection_links(@collection, name: :plants)

    render_serialized_collection(
      @collection,
      SpeciesLightSerializer,
      links: links
    )
  end

  def show
    @resource = Species.friendly.find(params[:id])

    render_serialized_resource(
      @resource.plant,
      PlantSerializer,
      meta: resource_metadata(@resource.plant)
    )
  end

  # Report an error
  def report
    @resource = Species.friendly.find(params[:id])
    rc = RecordCorrection.report!(
      record: @resource,
      user: current_user,
      change_type: params[:change_type] || 'update',
      notes: params[:notes]
    )
    render_serialized_resource(
      rc,
      RecordCorrectionSerializer,
      meta: resource_metadata(rc)
    )
  end

  def search
    search = params.require(:q)
    options = parse_search_options.merge(
      filters: 'main_species=true'
    )

    begin
      results = ::Search.search_species(search, options)
      links = search_collection_links(results, name: %i[plants], scope: %i[search api v1])

      render json: Panko::Response.new({
        data: serialize_search_data(results),
        meta: {
          total: results['nbHits']
        },
        links: links
      }.compact), status: :ok
    rescue MeiliSearch::CommunicationError => e
      Raven.capture_exception(e)

      @collection ||= Species.plants
      @collection = apply_search(collection)
      @pagy, @collection = pagy(@collection)
      links = collection_links(@collection, name: :plants)

      render_serialized_collection(
        @collection,
        SpeciesLightSerializer,
        links: links
      )
    end
  end

  def collection
    return @collection if @collection

    @collection = Genus.friendly.find(params[:genus_id]).species.plants if params[:genus_id]
    @collection = Zone.friendly.find(params[:zone_id]).species.plants if params[:zone_id]

    @collection ||= Species.plants.includes(:genus)

    @collection = apply_filters(@collection, Api::V1::SpeciesController::FILTERABLE_FIELDS)
    @collection = apply_filters_not(@collection, Api::V1::SpeciesController::FILTERABLE_NOT_FIELDS)
    @collection = apply_sort(@collection, Api::V1::SpeciesController::ORDERABLE_FIELDS, default_sort: { gbif_score: :desc })
    @collection = apply_range(@collection, Api::V1::SpeciesController::RANGEABLE_FIELDS)
    # @collection = apply_search(collection)

    @pagy, @collection = pagy(@collection)
    @collection
  end

end
