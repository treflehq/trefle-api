module Schemas
  module V1
    module Division
      def self.schema
        Helpers.object_of({
          id: { type: :integer },
          name: { type: :string },
          slug: { type: :string },
          subkingdom: Helpers.schema_href(schema: 'subkingdom'),
          links: Helpers.object_of({
            self: { type: :string },
            subkingdom: { type: :string }
          }, extras: { required: %w[self subkingdom] })
        }, extras: { required: %w[id name slug links subkingdom] })
      end
    end
  end
end
