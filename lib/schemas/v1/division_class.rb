module Schemas
  module V1
    module DivisionClass
      def self.schema
        Helpers.object_of({
          id: { type: :integer },
          name: { type: :string },
          slug: { type: :string },
          division: Helpers.schema_href(schema: 'division'),
          links: Helpers.object_of({
            self: { type: :string },
            division: { type: :string }
          }, extras: { required: %w[self] })
        }, extras: { required: %w[id name slug links] })
      end
    end
  end
end
