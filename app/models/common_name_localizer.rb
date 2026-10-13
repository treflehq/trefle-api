# The common name of species in one language, for the `lang` parameter of
# the species and plants endpoints (see CommonNameLocalization).
#
# A species has many common names per language, from several sources, with
# no rank among them. The one shown is chosen the same way on every request:
#
# 1. the name most sources agree on: the rows of one name are counted across
#    the tags of the language (`fr` and `fra` come from different imports)
#    and across spellings that differ only by case or accents;
# 2. on a tie, the name recorded first (lowest id);
# 3. spelled as the row under the ISO 639-1 tag itself has it (`Tomate`
#    rather than the `tomate` of the `fra` import), the first row otherwise.
#
# English is the species' own `common_name` column when it is set (that is
# the name the API has always shown). A species without a name in the
# language falls back to that English name; #localize says which language
# the name returned is in.
#
# The names are looked up in one query for every species the response
# shows, on the first name asked for: a page served from the serialization
# cache does not run it.
class CommonNameLocalizer
  attr_reader :lang

  # species_ids: the ids of the species the response will show, or a lambda
  # returning them, called on the first lookup only.
  def initialize(lang, species_ids: [])
    @lang = lang
    @species_ids = species_ids
    @names = nil
  end

  # [name, lang] for this species: its name in the requested language, or
  # its English common name (and 'en'), or [nil, nil] when it has neither.
  # fallback: the English name when the record is not the species itself
  # (a plant shows its main species' name, and falls back on its own).
  def localize(species_id, fallback: nil)
    return [fallback, 'en'] if lang == 'en' && fallback.present?

    name = names_for(species_id)
    return [name, lang] if name
    return [fallback, 'en'] if fallback.present?

    [nil, nil]
  end

  private

  def names_for(species_id)
    return nil if species_id.nil?

    if @names.nil?
      ids = @species_ids.respond_to?(:call) ? @species_ids.call : @species_ids
      @names = fetch([*ids, species_id].uniq)
    elsif !@names.key?(species_id)
      @names.merge!(fetch([species_id]))
    end
    @names[species_id]
  end

  # { species_id => name } for the species that have a name in the language;
  # the ids without one map to nil, so they are not looked up again.
  def fetch(ids)
    tags = CommonName.tags_for(lang)
    return ids.index_with(nil) if ids.empty? || tags.empty?

    rows = CommonName.connection.select_rows(CommonName.sanitize_sql_array([<<~SQL.squish, { lang: lang, ids: ids, tags: tags }]))
      SELECT DISTINCT ON (record_id) record_id, name
      FROM (
        SELECT record_id,
               (array_agg(btrim(name) ORDER BY (lang = :lang) DESC, id))[1] AS name,
               count(*) AS citations,
               min(id) AS first_id
        FROM common_names
        WHERE record_type = 'Species' AND record_id IN (:ids) AND lang IN (:tags) AND btrim(name) <> ''
        GROUP BY record_id, lower(unaccent(btrim(name)))
      ) names
      ORDER BY record_id, citations DESC, first_id
    SQL

    ids.index_with(nil).merge(rows.to_h {|id, name| [id.to_i, name] })
  end
end
