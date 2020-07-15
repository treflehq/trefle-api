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

      def self.filters
        Helpers.object_of(
          ::Api::V1::GenusController::FILTERABLE_FIELDS.map do |f|
            [f, { type: :string }]
          end.to_h
        )
      end

      def self.sorts
        Helpers.object_of(
          ::Api::V1::GenusController::ORDERABLE_FIELDS.map do |f|
            [f, { type: :string }]
          end.to_h
        )
      end
    end
  end
end
