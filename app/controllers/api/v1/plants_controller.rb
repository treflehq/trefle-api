class Api::V1::PlantsController < Api::ApiController
  include SparseFieldsets

  include WithCachedCount
  include CommonNameLocalization

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
      list_serializer,
      serializer_options: fields_serializer_options,
      links: links
    )
  end

  def show
    @resource = Species.friendly_or_synonym!(params[:id])
    ensure_species_in_parent!(@resource)

    render_serialized_resource(
      @resource.plant,
      PlantSerializer,
      serializer_options: fields_serializer_options,
      meta: resource_metadata(@resource.plant)
    )
  end

  # SparseFieldsets: the plant detail picks among the plant's keys, the lists
  # among the species detail's.
  def fields_serializer
    action_name == 'show' ? PlantSerializer : super
  end
  protected :fields_serializer

  # Report an error
  def report
    @resource = Species.friendly_or_synonym!(params[:id])
    rc = RecordCorrection.report!(
      record: @resource,
      user: current_user,
      change_type: params[:change_type] || 'update',
      notes: params[:notes]
    )
    render_serialized_resource(
      rc,
      RecordCorrectionSerializer,
      meta: resource_metadata(rc),
      status: :created
    )
  end

  # Search on database
  # @TODO @deprecated
  def full_search
    @collection ||= collection
    @collection = apply_search(collection)
    @pagy, @collection = pagy(@collection)
    links = collection_links(@collection, name: %i[plants], scope: %i[search api v1])

    render_serialized_collection(
      @collection,
      list_serializer,
      serializer_options: fields_serializer_options,
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
      range_fields: Api::V1::SpeciesController::RANGEABLE_FIELDS,
      field_aliases: ::Scopes::Species::FIELD_ALIASES,
      model: ::Species
    )
    options = {
      where: { main_species_id: nil }.merge(localize_common_name_search_conditions(search_params[:where])),
      includes: %i[genus plant],
      boost_by: [:gbif_score],
      fields: Species::SEARCH_FIELDS,
      order: search_params[:order]
    }.compact

    # On top of genus and plant, the associations the requested fields read (SparseFieldsets).
    @collection = Species.pagy_search(Species.search_term(search), **options, includes: options[:includes] + fields_preloads)
    # Page size (`per_page`, or its `limit` alias) is read by PerPage.
    @pagy, @collection = pagy_searchkick(@collection)

    links = collection_links(@collection, name: %i[plants], scope: %i[search api v1])

    render_serialized_collection(
      @collection,
      list_serializer,
      serializer_options: fields_serializer_options,
      links: links
    )
  end

  def collection
    return @collection if @collection

    @collection = Genus.friendly.find(params[:genus_id]).species.plants if params[:genus_id]
    @collection = Zone.resolve!(params[:zone_id]).all_species.plants if params[:zone_id]

    @collection ||= Species.plants

    # SpeciesLightSerializer reads `plant.slug` on top of `genus`, so both
    # need preloading regardless of which branch above set @collection (see
    # #281). Synonyms are no longer embedded in list payloads (only
    # `synonyms_count`, a column).
    @collection = @collection.preload(:plant, :genus, *fields_preloads)

    @collection = apply_filters(@collection, Api::V1::SpeciesController::FILTERABLE_FIELDS,
                                range_fields: Api::V1::SpeciesController::RANGEABLE_FIELDS, skip: common_name_filter_skip)
    @collection = apply_filters_not(@collection, Api::V1::SpeciesController::FILTERABLE_NOT_FIELDS, skip: common_name_filter_skip)
    @collection = apply_localized_common_name_filters(@collection)
    @collection = apply_sort(@collection, Api::V1::SpeciesController::ORDERABLE_FIELDS, default_sort: { gbif_score: :desc })
    @collection = apply_range(@collection, Api::V1::SpeciesController::RANGEABLE_FIELDS)
    # @collection = apply_search(collection)

    @pagy, @collection = pagy(@collection)
    @collection
  end

  protected

  # The plant detail shows all the species of the plant (main species,
  # subspecies, varieties...): their names under `lang` in one query.
  def localized_species_ids
    action_name == 'show' ? @resource.plant.species.ids : super
  end

end
