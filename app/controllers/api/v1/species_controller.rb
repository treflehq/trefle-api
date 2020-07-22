class Api::V1::SpeciesController < Api::ApiController

  include WithCachedCount

  FILTERABLE_FIELDS = %w[
    author
    bloom_months
    common_name
    duration
    family_common_name
    flower_conspicuous
    foliage_texture
    fruit_conspicuous
    fruit_seed_persistence
    growth_form
    growth_habit
    growth_rate
    leaf_retention
    lifespan
    ligneous_type
    rank
    scientific_name
    status
    vegetable
    growth_months
    bloom_months
    fruit_months
    flower_color
    foliage_color
    fruit_color
    edible_part
    establishment
    genus_name
  ].freeze

  FILTERABLE_NOT_FIELDS = %w[
    image_url
    author
    average_height_cm
    bibliography
    common_name
    edible_part
    family_common_name
    flower_color
    flower_conspicuous
    foliage_color
    foliage_texture
    frost_free_days_minimum
    fruit_color
    fruit_conspicuous
    fruit_seed_persistence
    ground_humidity
    growth_form
    growth_habit
    growth_rate
    images_count
    leaf_retention
    lifespan
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
    ph_maximum
    ph_minimum
    planting_days_to_harvest
    planting_row_spacing_cm
    planting_spread_cm
    rank
    scientific_name
    soil_nutriments
    soil_salinity
    soil_texture
    status
    synonyms_count
    sources_count
    toxicity
    vegetable
    year
  ].freeze

  ORDERABLE_FIELDS = %w[
    atmospheric_humidity
    author
    average_height_cm
    bibliography
    common_name
    duration
    edible
    family_common_name
    flower_color
    flower_conspicuous
    foliage_color
    foliage_texture
    frost_free_days_minimum
    fruit_color
    fruit_conspicuous
    fruit_seed_persistence
    ground_humidity
    growth_form
    growth_habit
    growth_rate
    images_count
    leaf_retention
    lifespan
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

  RANGEABLE_FIELDS = %w[
    atmospheric_humidity
    frost_free_days_minimum
    ground_humidity
    images_count
    light
    average_height_cm
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
    synonyms_count
    sources_count
    toxicity
    year
  ].freeze

  def index
    @collection = collection

    links = collection_links(@collection, name: %i[species index])

    render_serialized_collection(
      @collection,
      SpeciesLightSerializer,
      links: links
    )
  end

  def show
    @resource = Species.friendly.find(params[:id])

    render_serialized_resource(
      @resource,
      SpeciesSerializer,
      meta: {
        images_count: @resource.images_count,
        sources_count: @resource.sources_count,
        synonyms_count: @resource.synonyms_count
      }.merge(resource_metadata(@resource))
    )
  end

  # Search on database
  def full_search
    puts 'full_search'
    @collection ||= collection
    @collection = apply_search(collection)
    @pagy, @collection = pagy(@collection)
    links = collection_links(@collection, name: %i[species index], scope: %i[search api v1])

    render_serialized_collection(
      @collection,
      SpeciesLightSerializer,
      links: links
    )
  end

  # Search on meilisearch
  def quick_search
    puts 'quick_search'
    # search = params.require(:q)
    # options = parse_search_options
    # results = ::Search.search_species(search, options)
    # links = search_collection_links(results, name: %i[species index], scope: %i[search api v1])

    # render json: Panko::Response.new({
    #   data: serialize_search_data(results),
    #   meta: {
    #     total: results['nbHits']
    #   },
    #   links: links
    # }.compact), status: :ok
  end

  # @TODO this whole thing is ugly
  def search
    if params[:filter]&.is_a?(ActionController::Parameters) ||
       params[:filter_not]&.is_a?(ActionController::Parameters) ||
       params[:range]&.is_a?(ActionController::Parameters) ||
       params[:sort]&.is_a?(ActionController::Parameters)
      full_search
    else
      begin
        quick_search
      rescue MeiliSearch::CommunicationError => e
        Raven.capture_exception(e)

        full_search
      end
    end
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

  def collection
    return @collection if @collection

    @collection = Genus.friendly.find(params[:genus_id]).species if params[:genus_id]
    @collection = Plant.friendly.find(params[:plant_id]).species if params[:plant_id]
    @collection = Zone.friendly.find(params[:zone_id]).species if params[:zone_id]
    @collection ||= Species.all

    @collection = @collection.preload(:plant, :genus, :synonyms)

    @collection = apply_filters(@collection, FILTERABLE_FIELDS)
    @collection = apply_filters_not(@collection, FILTERABLE_NOT_FIELDS)
    @collection = apply_sort(@collection, ORDERABLE_FIELDS, default_sort: { gbif_score: :desc })
    @collection = apply_range(@collection, RANGEABLE_FIELDS)
    # @collection = apply_search(collection)

    @pagy, @collection = pagy(@collection)
    @collection
  end

end
