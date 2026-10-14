# The `lang` parameter of the species and plants endpoints (lists, details,
# searches, and the lists nested under a genus, a plant or a distribution).
#
# `?lang=fr` (an ISO 639-1 code) makes `common_name` the species' name in
# that language (see CommonNameLocalizer for how it is chosen) and adds
# `common_name_lang`, the language the name is actually in: a species
# without a French name keeps its English one, with `common_name_lang: "en"`.
# `filter[common_name]` and `filter_not[common_name]` then match the names
# of that language, ignoring case and accents. Without `lang`, nothing
# changes: `common_name` is the English name and the filters match it.
#
# A code the common names do not exist in answers 400 with the list of the
# accepted ones. Under `lang=en` the English `common_name` column counts as
# the English name, as it does in the response.
module CommonNameLocalization
  extend ActiveSupport::Concern

  class UnknownLanguageError < StandardError; end
  class TooManyMatchesError < StandardError; end

  # Search endpoints filter through the search index, which only knows the
  # English common name: a `lang` filter is turned into a list of species
  # ids. A filter on a name is a short list; `filter_not[common_name]=null`
  # (every species named in the language) is the long one.
  MAX_SEARCH_FILTER_IDS = 50_000

  included do
    rescue_from UnknownLanguageError, with: :render_unknown_language_response
    rescue_from TooManyMatchesError, with: ->(exception) { render_error(exception.message, :bad_request) }
  end

  # The requested ISO 639-1 code, lowercased, or nil without `lang`.
  def requested_lang
    return @requested_lang if defined?(@requested_lang)

    @requested_lang = parse_lang
  end

  def serialization_variant_parts
    super.merge(lang: requested_lang)
  end

  def serialization_context
    requested_lang ? super.merge(common_names: common_name_localizer) : super
  end

  protected

  # The ids of the species the response shows, so their names are looked up
  # in one query. Overridden by the actions that show something else than
  # @collection.
  def localized_species_ids
    @collection.respond_to?(:map) ? @collection.map(&:id) : []
  end

  def common_name_localizer
    @common_name_localizer ||= CommonNameLocalizer.new(requested_lang, species_ids: -> { localized_species_ids })
  end

  # The ActiveRecord path: filter[common_name] / filter_not[common_name] on
  # the names of the requested language. The callers skip `common_name` in
  # apply_filters / apply_filters_not when this applies.
  #
  # filter[common_name]=a,b keeps the species named a or b in the language,
  # `null` the species without a name in it; filter_not[common_name]=a
  # drops the species named a, `null` those without a name in it.
  def apply_localized_common_name_filters(collection)
    return collection unless requested_lang

    names, null = common_name_filter_values(:filter)
    id = ::Species.arel_table[:id]
    kept = []
    kept << id.in(localized_species(names).select(:id).arel) if names.any?
    kept << id.not_in(localized_species.select(:id).arel) if null
    collection = collection.where(kept.reduce(:or)) if kept.any?

    names, null = common_name_filter_values(:filter_not)
    collection = collection.where.not(id: localized_species(names).select(:id)) if names.any?
    collection = collection.where(id: localized_species.select(:id)) if null
    collection
  end

  # The search path: the same filters as conditions on the species ids, in
  # place of the English `common_name` of the Searchkick conditions.
  def localize_common_name_search_conditions(where)
    return where unless requested_lang

    conditions = []
    names, null = common_name_filter_values(:filter)
    kept = []
    kept << { id: localized_species_id_list(names) } if names.any?
    kept << { id: { not: localized_species_id_list } } if null
    conditions << (kept.one? ? kept.first : { _or: kept }) if kept.any?

    names, null = common_name_filter_values(:filter_not)
    conditions << { id: { not: localized_species_id_list(names) } } if names.any?
    conditions << { id: localized_species_id_list } if null

    where = where.except('common_name', :common_name)
    return where if conditions.empty?

    where.merge(_and: conditions)
  end

  def common_name_filter_skip
    requested_lang ? %w[common_name] : []
  end

  private

  # Without a request (a key computed outside of one, as the cache sweep's
  # check does), the default payload.
  def parse_lang
    raw = request && params[:lang]
    return nil if raw.nil?

    lang = raw.to_s.strip.downcase
    return lang if lang.match?(/\A[a-z]{2}\z/) && CommonName.languages.key?(lang)

    raise UnknownLanguageError, "Unknown lang: #{raw.to_s.inspect}. Use an ISO 639-1 code among the languages " \
                                "the common names exist in: #{CommonName.languages.keys.join(', ')}."
  end

  # [names, null?] of filter[common_name] or filter_not[common_name]:
  # the comma-separated names, and whether `null` is one of them.
  def common_name_filter_values(param_name)
    raw = params[param_name].is_a?(ActionController::Parameters) ? params[param_name][:common_name] : nil
    values = raw.to_s.split(',').map(&:strip).compact_blank
    nulls, names = values.partition {|value| value.casecmp?('null') }
    [names, nulls.any?]
  end

  # The species named in the requested language, those named one of `names`
  # when given. Under `lang=en` the name is also the species' own
  # `common_name` column: it is what `common_name` shows, so the filters
  # have to find it, with or without a row tagged `en`.
  def localized_species(names = nil)
    rows = CommonName.in_language(requested_lang)
    rows = rows.named(names) if names
    scope = ::Species.where(id: rows.select(:record_id))
    return scope unless requested_lang == 'en'

    scope.or(::Species.where(*english_column_condition(names)))
  end

  def english_column_condition(names)
    return ["btrim(species.common_name) <> ''"] unless names

    ['lower(unaccent(btrim(species.common_name))) IN (SELECT lower(unaccent(btrim(v))) FROM unnest(ARRAY[?]::text[]) AS v)',
     names.map(&:to_s)]
  end

  def localized_species_id_list(names = nil)
    ids = localized_species(names).limit(MAX_SEARCH_FILTER_IDS + 1).pluck(:id)
    raise TooManyMatchesError, "Too many species match this common_name filter in lang=#{requested_lang.inspect}; narrow it down." if ids.size > MAX_SEARCH_FILTER_IDS

    ids
  end

  def render_unknown_language_response(exception)
    render_error(exception.message, :bad_request, details: { accepted_values: CommonName.languages.keys })
  end
end
