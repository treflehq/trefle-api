module Schemas
  module Helpers
    def self.collection_schema(data: {}, links: nil, meta: nil)
      object_of({
        links: links ? object_of(links) : nil,
        meta: meta ? object_of(meta) : nil,
        data: array_of(data)
      }.compact)
    end

    def self.schema_href(schema: '')
      { '$ref' => "#/components/schemas/#{schema}" }
    end

    # The error envelope every 4xx/5xx answer shares (Schemas::V1::Error).
    def self.error_schema
      schema_href(schema: 'error')
    end

    def self.schema_array_href(schema: '')
      {
        type: :array,
        items: schema_href(schema: schema)
      }
    end

    def self.object_of(properties, extras: {})
      {
        type: :object,
        properties: properties
      }.compact.merge(extras)
    end

    def self.array_of(properties, extras: {})
      {
        type: :array,
        items: object_of(properties)
      }.compact.merge(extras)
    end

    # meta.dataset_version, on every API payload (CollectionRenderers,
    # DatasetVersion).
    DATASET_VERSION = {
      type: :string,
      nullable: true,
      description: 'The version of the data this response was served from: the date of the last data operation, ' \
                   '`YYYY.MM.DD`, with a `.N` suffix when several ran that day (also in the `X-Trefle-Data-Version` header). ' \
                   'Cite it with your access date; see https://trefle.io/citation and `GET /api/v1/changelog`. ' \
                   'Null on a database with no recorded data operation.',
      example: '2026.10.13'
    }.freeze

    # The `meta` object every paginated collection renders (see
    # CollectionRenderers#render_serialized_collection). `extra` adds the
    # endpoint-specific keys.
    def self.pagination_meta(extra = {})
      object_of({
        total: { type: :integer, description: 'The number of items in the whole collection' },
        page: { type: :integer, description: 'The current page' },
        per_page: { type: :integer, description: "The number of items per page (`per_page` parameter, 1 to #{::PerPage::MAX}, default #{::PerPage::DEFAULT})" },
        dataset_version: DATASET_VERSION
      }.merge(extra), extras: { required: %w[total page per_page dataset_version] })
    end

    def self.pagination_links
      object_of({
        self: {
          type: :string,
          description: 'A link to the current page of the collection'
        },
        first: {
          type: :string,
          description: 'A link to the first page of the collection'
        },
        next: {
          type: :string,
          description: 'A link to the next page of the collection'
        },
        prev: {
          type: :string,
          description: 'A link to the previous page of the collection'
        },
        last: {
          type: :string,
          description: 'A link to the last page of the collection'
        }
      }, extras: {
        required: ['self']
      })
    end
  end
end
