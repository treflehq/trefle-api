module WithCachedCount
  extend ActiveSupport::Concern

  # /plants and /species (the only two controllers that include this concern)
  # default-sort a ~490k-row table by gbif_score DESC with no WHERE clause
  # narrow enough to bound it (Sentry API-3Q, API-5J: 61k+ grouped slow-query
  # events). The existing gbif_score / (main_species_id, gbif_score) indexes
  # make page 1 fast, but a plain OFFSET/LIMIT still has to walk and discard
  # every preceding row, so deep pages get linearly slower with no ceiling --
  # not a missing index, an unbounded scan.
  #
  # Real cursor/keyset pagination (`WHERE (gbif_score, id) < (?, ?)`) is the
  # actual fix, but it replaces page-number links with an opaque cursor,
  # which changes the public pagination contract and overlaps #217
  # (client-controlled page size) -- that belongs there, as one contract
  # change, not two. Until then, cap how deep OFFSET is allowed to go and
  # fail fast with a documented 400 instead of degrading silently. 2,500
  # pages * 20 items/page = a 50,000-row OFFSET, comfortably inside what
  # Postgres discards in low-double-digit milliseconds against an index
  # (see the PR body for EXPLAIN ANALYZE timings at that depth).
  MAX_PAGE_DEPTH = 2_500

  class PageDepthExceededError < StandardError; end

  def pagy_get_vars(collection, vars)
    vars[:page] ||= params[vars[:page_param] || Pagy::DEFAULT[:page_param]]

    if vars[:page].to_i > MAX_PAGE_DEPTH
      raise PageDepthExceededError, "page must be #{MAX_PAGE_DEPTH} or lower. Narrow the results with a " \
        'filter or range instead of paging deep into the full collection. See https://docs.trefle.io'
    end

    vars[:count] ||= cache_count(collection)
    vars
  end

  # add Rails.cache wrapper around the count call
  def cache_count(collection)
    cache_key = "pagy-#{collection.model.name}:#{collection.to_sql}"
    Rails.logger.debug { "[cache_count] caching count for #{collection.model.name}" }
    Rails.cache.fetch(cache_key, expires_in: 30.seconds) do
      Rails.logger.debug { "[cache_count] count cached for #{collection.model.name}" }
      collection.count(:all)
    end
  end
end
