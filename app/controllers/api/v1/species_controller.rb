class Api::V1::SpeciesController < Api::ApiController

  include WithCachedCount

  FILTERABLE_FIELDS = %w[
    author
    bloom_months
    common_name
    days_to_harvest
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
    genus_name
    growth_form
    growth_habit
    growth_months
    growth_rate
    leaf_retention
    ligneous_type
    rank
    scientific_name
    status
    vegetable
  ].freeze

  FILTERABLE_NOT_FIELDS = %w[
    author
    average_height_cm
    bibliography
    common_name
    days_to_harvest
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
    genus_name
    ground_humidity
    growth_form
    growth_habit
    growth_rate
    image_url
    images_count
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

  ORDERABLE_FIELDS = %w[
    atmospheric_humidity
    author
    average_height_cm
    bibliography
    common_name
    duration
    days_to_harvest
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
    ground_humidity
    growth_form
    growth_habit
    growth_rate
    images_count
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
    days_to_harvest
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
  # @TODO @deprecated
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
      where: search_params[:where],
      includes: %i[synonyms genus plant],
      boost_by: [:gbif_score],
      fields: ['common_name^10', 'common_names^8', 'scientific_name^5', 'synonyms^3', 'author', 'genus', 'family', 'family_common_name', 'distributions'],
      order: search_params[:order]
    }.compact

    @collection = Species.pagy_search(search, **options)
    @pagy, @collection = pagy_searchkick(@collection, items: (params[:limit] || 20).to_i)

    links = collection_links(@collection, name: %i[species index], scope: %i[search api v1])

    render_serialized_collection(
      @collection,
      SpeciesLightSerializer,
      links: links
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
      meta: resource_metadata(rc),
      status: :created
    )
  end

  def collection
    return @collection if @collection

    @collection = Genus.friendly.find(params[:genus_id]).species if params[:genus_id]
    @collection = Plant.friendly.find(params[:plant_id]).species if params[:plant_id]
    @collection = Zone.friendly.find(params[:zone_id].to_s.downcase).all_species if params[:zone_id]
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
