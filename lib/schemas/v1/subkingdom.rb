module Schemas
  module V1
    module Subkingdom
      def self.schema
        Helpers.object_of({
          id: { type: :integer },
          name: { type: :string },
          slug: { type: :string },
          kingdom: Helpers.schema_href(schema: 'kingdom'),
          links: Helpers.object_of({
            self: { type: :string },
            kingdom: { type: :string }
          }, extras: { required: %w[self kingdom] })
        }, extras: { required: %w[id name slug links kingdom] })
      end
    end
  end
end
