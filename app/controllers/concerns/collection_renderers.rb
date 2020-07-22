module CollectionRenderers
  extend ActiveSupport::Concern

  def filtered_params
    params.to_unsafe_h.without(
      'action', 'controller', 'token'
    ).deep_symbolize_keys
  end

  def collection_links(collection, scope: %i[api v1], name: nil) # rubocop:todo Metrics/PerceivedComplexity
    {
      self: polymorphic_path([*scope, *[*name] || collection.table_name], filtered_params),
      first: polymorphic_path([*scope, *[*name] || collection.table_name], filtered_params.merge({ page: 1 })),
      prev: @pagy.prev && polymorphic_path([*scope, *[*name] || collection.table_name], filtered_params.merge({ page: @pagy.prev })),
      next: @pagy.next && polymorphic_path([*scope, *[*name] || collection.table_name], filtered_params.merge({ page: @pagy.next })),
      last: polymorphic_path([*scope, *[*name] || collection.table_name], filtered_params.merge({ page: @pagy.last }))
    }.compact
  end

  def parse_search_options
    parse_search_pagination_options.merge(parse_search_filters_options)
  end

  def parse_search_filters_options
    {}
  end

  def parse_search_pagination_options
    search = params.require(:q)
    page = params[:page] || nil
    params[:limit] = 50 if params[:limit] && params[:limit].to_i > 50
    limit = params[:limit] || 20
    offset = params[:offset]&.to_i || (page && (page.to_i - 1) * limit) || 0
    { limit: limit, offset: offset }
  end

  def serialize_search_data(results)
    results['hits'].map do |hit|
      hit.merge({
        links: {
          self: api_v1_species_path(hit['slug'] || hit['id']),
          plant: api_v1_plant_path(hit['slug'] || hit['id']),
          genus: api_v1_genus_path(hit['genus_id'])
        }
      })
    end
  end

  def search_collection_links(collection, scope: %i[api v1], name: nil)
    currpage = params[:page]&.to_i || 1
    {
      self: polymorphic_path([*scope, *name], filtered_params),
      first: polymorphic_path([*scope, *name], filtered_params.merge({ page: 1 })),
      prev: collection['offset'] > 0 && polymorphic_path([*scope, *name], filtered_params.merge({ page: currpage - 1 })) || nil,
      next: (collection['offset'] + collection['limit']) < collection['nbHits'] && polymorphic_path([*scope, *name], filtered_params.merge({ page: currpage + 1 })) || nil,
      last: polymorphic_path([*scope, *name], filtered_params.merge({ page: (collection['nbHits'] / collection['limit']).to_i + 1 }))
    }.compact
  end

  def resource_metadata(resource)
    {
      last_modified: resource.updated_at
    }
  end

  def render_serialized_collection(collection, serializer, serializer_options: {}, links: nil, meta: {})
    options = {
      each_serializer: serializer
    }.merge(serializer_options)

    meta = {
      total: @pagy.count || collection.count
    }.merge(meta)

    render json: Panko::Response.new({
      data: Panko::ArraySerializer.new(collection, options),
      links: links,
      meta: meta
    }.compact)
  end

  def render_serialized_resource(resource, serializer, serializer_options: {}, links: nil, meta: {})
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
      render(json: serialized_resource) && return
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
    render json: {}, status: 200
  end

  def render_destroyed
    render json: nil, status: 204
  end
end
