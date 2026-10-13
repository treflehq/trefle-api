module CollectionRenderers
  extend ActiveSupport::Concern

  def filtered_params
    params.to_unsafe_h.without(
      'action', 'controller', 'token'
    ).deep_symbolize_keys
  end

  def collection_links(collection, scope: %i[api v1], name: nil)
    route = [*scope, *[*name] || collection.table_name]
    base = pagination_params
    {
      self: polymorphic_path(route, base),
      first: polymorphic_path(route, base.merge({ page: 1 })),
      prev: @pagy.prev && polymorphic_path(route, base.merge({ page: @pagy.prev })),
      next: @pagy.next && polymorphic_path(route, base.merge({ page: @pagy.next })),
      last: polymorphic_path(route, base.merge({ page: @pagy.last }))
    }.compact
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

  def cache_or_serialize(collection, serializer, serializer_options: {})
    Rails.logger.debug { "[cache_or_serialize] serializer=#{serializer} options=#{serializer_options}" }
    collection.map do |resource|
      end_key = "collection/#{serializer}/#{resource.cache_key}-#{resource.cache_version}"
      Rails.cache.fetch(end_key) do
        serializer.new(serializer_options).serialize(resource)
      end
    end
  end

  def render_serialized_resource(resource, serializer, serializer_options: {}, links: nil, meta: {}, status: :ok)
    expires_in serializer_options[:delay] || 1.week

    end_key = "#{serializer}/#{resource.cache_key}-#{resource.cache_version}"

    if stale?(etag: end_key, template: false, last_modified: resource.updated_at) # rubocop:todo Style/GuardClause
      serialized_resource = Rails.cache.fetch(end_key) do
        Panko::Response.new({
          data: serializer.new(serializer_options).serialize(resource),
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
