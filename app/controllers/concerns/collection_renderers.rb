module CollectionRenderers
  extend ActiveSupport::Concern
  include SerializationVariant

  def filtered_params
    params.to_unsafe_h.without(
      'action', 'controller', 'token'
    ).deep_symbolize_keys
  end

  def collection_links(collection, scope: %i[api v1], name: nil)
    route = [*scope, *[*name] || collection.table_name]
    base = pagination_params
    last = last_reachable_page
    {
      self: polymorphic_path(route, base),
      first: polymorphic_path(route, base.merge({ page: 1 })),
      prev: @pagy.prev && polymorphic_path(route, base.merge({ page: @pagy.prev })),
      next: @pagy.next && @pagy.next <= last ? polymorphic_path(route, base.merge({ page: @pagy.next })) : nil,
      last: polymorphic_path(route, base.merge({ page: last }))
    }.compact
  end

  # The collection's last page, or the deepest page the controller lets a
  # client reach (WithCachedCount#deepest_page) when that comes first: on
  # /species and /plants the full collection runs past the 50,000-row
  # horizon, and a `last` link beyond it would answer 400.
  def last_reachable_page
    return @pagy.last unless respond_to?(:deepest_page, true)

    [@pagy.last, deepest_page(@pagy.items)].min
  end

  # The query string every pagination link is built from. When the client
  # chose a page size (through `per_page` or its `limit` alias, see PerPage)
  # the links carry it as `per_page`, so following them keeps the page size
  # whichever spelling the request used.
  def pagination_params
    base = filtered_params
    return base unless respond_to?(:per_page_requested?, true) && per_page_requested?

    base.without(:limit).merge(per_page: @pagy.items)
  end

  def resource_metadata(resource)
    {
      last_modified: resource.updated_at
    }
  end

  def render_serialized_collection(collection, serializer, serializer_options: {}, links: nil, meta: {})
    Rails.logger.debug { "[render_serialized_collection] serializer=#{serializer} options=#{serializer_options}" }

    # options = {
    #   each_serializer: serializer
    # }.merge(serializer_options)

    meta = {
      total: @pagy.count || collection.count,
      page: @pagy.page,
      per_page: @pagy.items
    }.merge(meta)

    render json: Panko::Response.new({
      data: cache_or_serialize(collection, serializer, serializer_options: serializer_options),
      links: links,
      meta: meta
    }.compact)

    # render json: Panko::Response.new({
    #   data: Panko::ArraySerializer.new(collection, options),
    #   links: links,
    #   meta: meta
    # }.compact)
  end

  # Serialized payloads are kept in the cache store (memcached in production)
  # and the detail key doubles as the ETag. A record's cache_key/cache_version
  # only move when the row does, so without the release in the key a deploy
  # that changed a payload kept serving the previous release's version of
  # every record already cached: after 2.9.7, rosa-canina still came back
  # with its 1,083 synonyms, list pages mixed `synonyms[]` rows with
  # `synonyms_count` rows, and conditional requests answered 304 on them.
  #
  # The key carries the application version and the image revision (the git
  # tag baked in as APP_REVISION), so every release starts on fresh keys; the
  # previous release's entries are never read again and age out of memcached
  # on their own (LRU, and the TTL below).
  def self.release_cache_namespace
    [TrefleAdmin::Application::VERSION, ENV['APP_REVISION'].presence].compact.join('+')
  end

  # A payload also embeds associated records (genus, family, autonym
  # synonyms, images...) whose changes don't move the record's own
  # updated_at; the TTL bounds how long such a change can stay invisible.
  SERIALIZATION_CACHE_TTL = 1.day

  # The one key builder for serialized payloads: the cache entries of the
  # collection rows and of the detail, and the detail's ETag. The variant
  # (SerializationVariant) keeps apart the payloads a query parameter
  # shapes, so `?lang=fr` never serves, nor answers 304 to, the default one.
  def serialization_cache_key(serializer, resource, scope: nil)
    [
      scope,
      CollectionRenderers.release_cache_namespace,
      serializer.name,
      serialization_variant,
      "#{resource.cache_key}-#{resource.cache_version}"
    ].compact.join('/')
  end

  # When the process started; see http_last_modified.
  BOOTED_AT = Time.current

  # Last-Modified of a detail response. A client that sends only
  # If-Modified-Since (no If-None-Match) would otherwise get a 304 on a record
  # untouched since before the release, whatever the release changed in its
  # payload. The response cannot be older than the code that built it.
  def http_last_modified(resource)
    [resource.updated_at, BOOTED_AT].compact.max
  end

  def cache_or_serialize(collection, serializer, serializer_options: {})
    Rails.logger.debug { "[cache_or_serialize] serializer=#{serializer} options=#{serializer_options}" }
    collection.map do |resource|
      end_key = serialization_cache_key(serializer, resource, scope: 'collection')
      Rails.cache.fetch(end_key, expires_in: SERIALIZATION_CACHE_TTL) do
        serializer.new(serializer_options_with_context(serializer_options)).serialize(resource)
      end
    end
  end

  def render_serialized_resource(resource, serializer, serializer_options: {}, links: nil, meta: {}, status: :ok)
    expires_in serializer_options[:delay] || 1.week

    end_key = serialization_cache_key(serializer, resource)

    if stale?(etag: end_key, template: false, last_modified: http_last_modified(resource)) # rubocop:todo Style/GuardClause
      serialized_resource = Rails.cache.fetch(end_key, expires_in: SERIALIZATION_CACHE_TTL) do
        Panko::Response.new({
          data: serializer.new(serializer_options_with_context(serializer_options)).serialize(resource),
          links: links,
          meta: meta
        }.compact)
      end
      render(json: serialized_resource, status: status) && return
    end
  end

  # We'll try to standardize the way we send errors here
  def render_error(messages, code = 500)
    render json: { error: true, messages: messages }, status: code
  end

  # We'll try to standardize the way we send errors here
  def render_unauthorized(messages, code = :unauthorized)
    render json: { error: true, messages: messages }, status: code
  end

  def render_empty
    render json: {}, status: :ok
  end

  def render_destroyed
    render json: nil, status: :no_content
  end
end
