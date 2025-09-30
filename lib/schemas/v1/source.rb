module Schemas
  module V1
    module Source
      def self.schema
        Helpers.object_of(
          {
            id: { type: :string, nullable: true },
            name: { type: :string },
            url: { type: :string, nullable: true },
            last_update: { type: :string },
            citation: { type: :string, nullable: true }
          },
          extras: { required: %w[name last_update] }
        )
      end
    end
  end
end
