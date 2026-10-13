module Schemas
  module V1
    module Family
      def self.schema
        Helpers.object_of({
          id: { type: :integer },
          name: { type: :string },
          common_name: { type: :string, nullable: true },
          slug: { type: :string },
          division_order: Helpers.schema_href(schema: 'division_order'),
          links: Helpers.object_of({
            self: { type: :string },
            division_order: { type: :string }
          }, extras: { required: %w[self] })
        }, extras: { required: %w[id name slug links] })
      end
    end
  end
end
