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

      def self.filters
        Helpers.object_of(
          ::Api::V1::FamiliesController::FILTERABLE_FIELDS.map do |f|
            [f, { type: :string }]
          end.to_h
        )
      end

      def self.sorts
        Helpers.object_of(
          ::Api::V1::FamiliesController::ORDERABLE_FIELDS.map do |f|
            [f, { type: :string }]
          end.to_h
        )
      end
    end
  end
end
