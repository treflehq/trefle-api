module Schemas
  module V1
    module DivisionOrder
      def self.schema
        Helpers.object_of({
          id: { type: :integer },
          name: { type: :string },
          slug: { type: :string },
          division_class: Helpers.schema_href(schema: 'division_class'),
          links: Helpers.object_of({
            self: { type: :string },
            division_class: { type: :string }
          }, extras: { required: %w[self] })
        }, extras: { required: %w[id name slug links] })
      end
    end
  end
end
