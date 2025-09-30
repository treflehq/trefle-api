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
