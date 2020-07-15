module Schemas
  module V1
    module Kingdom
      def self.schema
        Helpers.object_of({
          id: { type: :integer },
          name: { type: :string },
          slug: { type: :string },
          links: Helpers.object_of({
            self: { type: :string }
          }, extras: { required: %w[self] })
        }, extras: { required: %w[id name slug links] })
      end
    end
  end
end
