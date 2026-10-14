class Api::V1::SpeciesController < Api::ApiController
  include SparseFieldsets

  include WithCachedCount
  include CommonNameLocalization

  FILTERABLE_FIELDS = %w[
    author
    biological_type
    bloom_months
    common_name
    complete_data
    completion_ratio
    duration
    establishment
    edible
    edible_part
    family_common_name
    family_name
    flower_color
    flower_conspicuous
    foliage_color
    foliage_texture
    fruit_color
    fruit_conspicuous
    fruit_months
    fruit_seed_persistence
    fruit_shape
    genus_name
    growth_form
    growth_habit
    growth_months
    growth_rate
    inflorescence_type
    leaf_retention
    ligneous_type
    nitrogen_fixation
    rank
    scientific_name
    sexuality
    status
    vegetable
  ].freeze

  FILTERABLE_NOT_FIELDS = %w[
    author
    average_height_cm
    bibliography
    biological_type
    common_name
    complete_data
    completion_ratio
    edible_part
    family_common_name
    family_name
    flower_color
    flower_conspicuous
    foliage_color
    foliage_texture
    frost_free_days_minimum
    fruit_color
    fruit_conspicuous
    fruit_seed_persistence
    fruit_shape
    genus_name
    ground_humidity
    growth_form
    growth_habit
    growth_rate
    image_url
    images_count
    inflorescence_type
    leaf_retention
    light
    ligneous_type
    maximum_height_cm
    maximum_precipitation_mm
    maximum_temperature_deg_c
    maximum_temperature_deg_f
    minimum_precipitation_mm
    minimum_root_depth_cm
    minimum_temperature_deg_c
    minimum_temperature_deg_f
    nitrogen_fixation
    ph_maximum
    ph_minimum
    planting_days_to_harvest
    planting_row_spacing_cm
    planting_spread_cm
    rank
    scientific_name
    sexuality
    soil_nutriments
    soil_salinity
    soil_texture
    sources_count
    status
    synonyms_count
    toxicity
    vegetable
    year
  ].freeze

  ORDERABLE_FIELDS = %w[
    atmospheric_humidity
    author
    average_height_cm
    bibliography
    biological_type
    common_name
    complete_data
    completion_ratio
    duration
    edible
    family_common_name
    family_name
    flower_color
    flower_conspicuous
    foliage_color
    foliage_texture
    frost_free_days_minimum
    fruit_color
    fruit_conspicuous
    fruit_seed_persistence
    fruit_shape
    ground_humidity
    growth_form
    growth_habit
    growth_rate
    images_count
    inflorescence_type
    leaf_retention
    light
    ligneous_type
    maximum_height_cm
    maximum_precipitation_mm
    maximum_temperature_deg_c
    maximum_temperature_deg_c
    maximum_temperature_deg_f
    maximum_temperature_deg_f
    minimum_precipitation_mm
    minimum_root_depth_cm
    minimum_temperature_deg_c
    minimum_temperature_deg_f
    ph_maximum
    ph_minimum
    planting_days_to_harvest
    planting_row_spacing_cm
    planting_spread_cm
    rank
    scientific_name
    sexuality
    soil_nutriments
    soil_salinity
    soil_texture
    sources_count
    status
    synonyms_count
    toxicity
    updated_at
    vegetable
    year
  ].freeze

  RANGEABLE_FIELDS = %w[
    atmospheric_humidity
    average_height_cm
    completion_ratio
    frost_free_days_minimum
    ground_humidity
    images_count
    light
    maximum_height_cm
    maximum_precipitation_mm
    maximum_temperature_deg_c
    maximum_temperature_deg_f
    minimum_precipitation_mm
    minimum_root_depth_cm
    minimum_temperature_deg_c
    minimum_temperature_deg_f
    ph_maximum
    ph_minimum
    planting_days_to_harvest
    planting_row_spacing_cm
    planting_spread_cm
    soil_nutriments
    soil_salinity
    soil_texture
    sources_count
    synonyms_count
    toxicity
    year
  ].freeze

  def index
    @collection = collection

    links = collection_links(@collection, name: %i[species index])

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
      @resource,
      SpeciesSerializer,
      serializer_options: fields_serializer_options,
      meta: {
        images_count: @resource.images_count,
        sources_count: @resource.sources_count,
        synonyms_count: @resource.synonyms_with_autonyms_count
      }.merge(resource_metadata(@resource))
    )
  end

  # SparseFieldsets: the detail picks among its own keys (synonyms included),
  # the lists among SpeciesListSerializer's.
  def fields_serializer
    action_name == 'show' ? SpeciesSerializer : super
  end
  protected :fields_serializer

  # Provenance of the species trait values: one row per (attribute, source)
  # claim, including superseded and rejected ones (transparency)
  def facts
    @resource = Species.friendly_or_synonym!(params[:id])
    facts = @resource.species_facts.order(:attribute_name, :source, :id)

    render json: Panko::Response.new(
      data: Panko::ArraySerializer.new(facts, each_serializer: SpeciesFactSerializer).to_a,
      meta: { total: facts.length }.merge(dataset_version_meta)
    )
  end

  # Search on database
  # @TODO @deprecated
  def full_search
    @collection ||= collection
    @collection = apply_search(collection)
    @pagy, @collection = pagy(@collection)
    links = collection_links(@collection, name: %i[species index], scope: %i[search api v1])

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
      where: localize_common_name_search_conditions(search_params[:where]),
      includes: %i[genus plant],
      boost_by: [:gbif_score],
      fields: Species::SEARCH_FIELDS,
      order: search_params[:order]
    }.compact

    # On top of genus and plant, the associations the requested fields read (SparseFieldsets).
    @collection = Species.pagy_search(Species.search_term(search), **options, includes: options[:includes] + fields_preloads)
    # Page size (`per_page`, or its `limit` alias) is read by PerPage.
    @pagy, @collection = pagy_searchkick(@collection)

    links = collection_links(@collection, name: %i[species index], scope: %i[search api v1])

    render_serialized_collection(
      @collection,
      list_serializer,
      serializer_options: fields_serializer_options,
      links: links
    )
  end

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

  def collection
    return @collection if @collection

    @collection = Genus.friendly.find(params[:genus_id]).species if params[:genus_id]
    @collection = Plant.friendly.find(params[:plant_id]).species if params[:plant_id]
    @collection = Zone.resolve!(params[:zone_id]).all_species if params[:zone_id]
    @collection ||= Species.all
    # Hidden records (Species::HIDDEN_REASONS) resolve by slug, never in a list.
    @collection = @collection.listed

    # SpeciesLightSerializer reads `plant.slug` and `genus`; synonyms are no
    # longer embedded in list payloads (only `synonyms_count`, a column).
    @collection = @collection.preload(:plant, :genus, *fields_preloads)

    @collection = apply_filters(@collection, FILTERABLE_FIELDS, range_fields: RANGEABLE_FIELDS, skip: common_name_filter_skip)
    @collection = apply_filters_not(@collection, FILTERABLE_NOT_FIELDS, skip: common_name_filter_skip)
    @collection = apply_localized_common_name_filters(@collection)
    @collection = apply_sort(@collection, ORDERABLE_FIELDS, default_sort: { gbif_score: :desc })
    @collection = apply_range(@collection, RANGEABLE_FIELDS)
    # @collection = apply_search(collection)

    @pagy, @collection = pagy(@collection)
    @collection
  end

end
