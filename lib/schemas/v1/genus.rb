module Schemas
  module V1
    module Genus
      def self.schema
        Helpers.object_of({
          id: { type: :integer },
          name: { type: :string },
          slug: { type: :string },
          family: Helpers.schema_href(schema: 'family'),
          links: Helpers.object_of({
            self: { type: :string },
            family: { type: :string }
          }, extras: { required: %w[self] })
        }, extras: { required: %w[id name slug links] })
      end
    end
  end
end
