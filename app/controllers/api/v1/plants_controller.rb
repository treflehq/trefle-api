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

  # Search on database
  # @TODO @deprecated
  def full_search
    puts 'full_search'
    @collection ||= collection
    @collection = apply_search(collection)
    @pagy, @collection = pagy(@collection)
    links = collection_links(@collection, name: %i[plants], scope: %i[search api v1])

    render_serialized_collection(
      @collection,
      SpeciesLightSerializer,
      links: links
    )
  end

  # Search on elasticsearch
  def search
    search = params.require(:q)
    search_params = search_params(
      filter_not_fields: Api::V1::SpeciesController::FILTERABLE_NOT_FIELDS,
      filter_fields: Api::V1::SpeciesController::FILTERABLE_FIELDS,
      order_fields: Api::V1::SpeciesController::ORDERABLE_FIELDS,
      range_fields: Api::V1::SpeciesController::RANGEABLE_FIELDS
    )
    options = {
      where: { main_species_id: nil }.merge(search_params[:where]),
      includes: %i[synonyms genus plant],
      boost_by: [:gbif_score],
      fields: ['common_name^10', 'scientific_name^5', 'author', 'genus', 'family', 'family_common_name'],
      order: search_params[:order]
    }.compact

    @collection = Species.pagy_search(search, options)
    @pagy, @collection = pagy_searchkick(@collection, items: (params[:limit] || 20).to_i)

    links = collection_links(@collection, name: %i[plants], scope: %i[search api v1])

    render_serialized_collection(
      @collection,
      SpeciesLightSerializer,
      links: links
    )
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
