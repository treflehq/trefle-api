# The `fields` parameter of the species and plants endpoints: the top-level
# keys of the payload to return, `id` and `slug` always included.
#
#   /species?fields=scientific_name,growth,flower
#   /plants/{id}?fields=common_name,main_species
#
# On a list, any field of the species detail can be asked for (`growth`,
# `specifications`, `distributions`, `common_names`...; the rows are then
# rendered by SpeciesListSerializer instead of SpeciesLightSerializer), so
# reading the traits of a page no longer takes one detail call per species,
# and a light payload can be made lighter still. `synonyms` stays on the
# detail (`links.synonyms` on a list).
#
# A field is a top-level key; groups (`growth`, `flower`, `specifications`)
# come whole. An unknown field answers 400 with the valid ones. The
# associations the requested fields read are preloaded for the whole page;
# the fields that embed a collection per row (EMBEDDED_COLLECTIONS) cap the
# page size at EMBEDDED_COLLECTIONS_MAX_PER_PAGE.
module SparseFieldsets
  extend ActiveSupport::Concern

  class InvalidFieldsError < StandardError; end

  ALWAYS_INCLUDED = %w[id slug].freeze

  # What a list preloads for a requested field, on top of the plant and
  # genus every row reads.
  PRELOADS = {
    'images' => :species_images,
    'common_names' => :common_names,
    'distribution' => { species_distributions: :zone },
    'distributions' => { species_distributions: :zone },
    'sources' => { foreign_sources_plants: :foreign_source },
    'family' => { genus: :family }
  }.freeze

  # The fields whose size grows with the species (a widespread species has
  # hundreds of zones): 20 such rows per page at most.
  EMBEDDED_COLLECTIONS = %w[images common_names distribution distributions sources].freeze
  EMBEDDED_COLLECTIONS_MAX_PER_PAGE = 20

  included do
    rescue_from InvalidFieldsError, with: :render_invalid_fields_response
  end

  # The requested fields, validated, sorted and without the ones always
  # included, or nil without `fields`.
  def requested_fields
    return @requested_fields if defined?(@requested_fields)

    @requested_fields = parse_fields
  end

  def serialization_variant_parts
    super.merge(fields: requested_fields&.join(','))
  end

  protected

  # The serializer this action renders its records with when `fields` is
  # given, whose keys are the valid fields. Controllers override it per action.
  def fields_serializer
    SpeciesListSerializer
  end

  # The serializer of a list: the light one unless `fields` asks for more.
  def list_serializer
    requested_fields ? fields_serializer : SpeciesLightSerializer
  end

  # Panko's `only:` for the requested fields, to pass as serializer_options.
  def fields_serializer_options
    return {} unless requested_fields

    filters = fields_serializer.field_filters
    { only: (ALWAYS_INCLUDED + requested_fields).map {|field| filters.fetch(field) } }
  end

  # The associations the requested fields read, for every row of the page.
  def fields_preloads
    (requested_fields || []).filter_map {|field| PRELOADS[field] }.uniq
  end

  def per_page_max
    embedded_collections_requested.any? ? [EMBEDDED_COLLECTIONS_MAX_PER_PAGE, super].min : super
  end

  def per_page_max_reason
    fields = embedded_collections_requested
    fields.any? ? " with fields=#{fields.join(',')}" : super
  end

  private

  def embedded_collections_requested
    action_name == 'show' ? [] : (requested_fields || []) & EMBEDDED_COLLECTIONS
  end

  # Without a request (a key computed outside of one, as the cache sweep's
  # check does), no fields.
  def parse_fields
    raw = request && params[:fields]
    return nil if raw.nil?
    raise InvalidFieldsError, fields_message('fields must be a comma-separated list of field names.') unless raw.is_a?(String)

    fields = raw.split(',').map(&:strip).compact_blank.uniq
    return nil if fields.empty?

    unknown = fields - fields_serializer.field_names
    raise InvalidFieldsError, fields_message("Unknown field#{'s' if unknown.size > 1}: #{unknown.join(', ')}.") if unknown.any?

    fields = (fields - ALWAYS_INCLUDED).sort
    fields.presence || ALWAYS_INCLUDED.dup
  end

  def fields_message(problem)
    "#{problem} Valid fields are: #{fields_serializer.field_names.sort.join(', ')}."
  end

  def render_invalid_fields_response(exception)
    render_error(exception.message, :bad_request, details: { accepted_values: fields_serializer.field_names.sort })
  end
end
