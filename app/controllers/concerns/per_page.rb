# Client-controlled page size on every /api/v1 collection (#217, #132).
#
# `per_page` is the documented parameter; `limit` is kept as an alias because
# /species/search and /plants/search accepted it (uncapped) before this
# concern existed. Both land in Pagy's `items` var, so the OFFSET/LIMIT
# pagination, the Searchkick pagination and the `links` all see one number.
#
# The ceiling is 100: it is Pagy's own default for the items extra
# (`DEFAULT[:max_items]`), and a page of 100 species already weighs a few
# hundred KB once serialized. Anything bigger is a bulk export, which the
# rate limit (60 req/min, config/initializers/rack_attack.rb) is not sized
# for -- a client at 100/page already pulls 5x more rows per quota than the
# default did. The deep-offset guard (WithCachedCount::MAX_OFFSET) is
# expressed in rows, so a bigger page never reaches deeper into the table
# than the default one did.
module PerPage
  extend ActiveSupport::Concern

  DEFAULT = 20
  MAX = 100
  PARAMS = %w[per_page limit].freeze

  class InvalidPageSizeError < StandardError; end

  # Pagy::Backend#pagy_get_vars. Set here (and not from the items extra) so
  # the validation below runs before Pagy ever sees the value: the extra
  # silently clamps, we want a 400.
  def pagy_get_vars(collection, vars)
    vars[:items] ||= per_page
    super
  end

  # Pagy::SearchkickExtra::Backend#pagy_searchkick_get_vars (the search
  # endpoints build their Pagy object from the Searchkick results).
  def pagy_searchkick_get_vars(collection, vars)
    vars[:items] ||= per_page
    super
  end

  # The page size this request asked for, validated, or DEFAULT when the
  # request did not specify one. Memoized: the links and the meta read it
  # after the collection has been paginated.
  def per_page
    @per_page ||= parse_per_page
  end

  # True when the client set the page size explicitly (through either
  # parameter), so the pagination links can carry it along.
  def per_page_requested?
    PARAMS.any? {|name| params[name].present? }
  end

  private

  def parse_per_page
    name = PARAMS.find {|key| params[key].present? }
    return DEFAULT unless name

    raw = params[name].to_s.strip
    max = per_page_max
    unless raw.match?(/\A\d+\z/) && (1..max).cover?(raw.to_i)
      raise InvalidPageSizeError, "#{name} must be an integer between 1 and #{max}#{per_page_max_reason}; got #{raw.inspect}. " \
        "The default is #{DEFAULT}."
    end

    raw.to_i
  end

  # The ceiling of this request, MAX unless the request asks for heavier rows
  # (SparseFieldsets lowers it for the embedded collections).
  def per_page_max
    MAX
  end

  # Why the ceiling is below MAX, for the error message (" with fields=...").
  def per_page_max_reason
    nil
  end
end
