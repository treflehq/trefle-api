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
            citation: { type: :string, nullable: true },
            licence: { type: :string, nullable: true, description: 'The SPDX identifier of the licence this source publishes its data under, when known' },
            licence_url: { type: :string, nullable: true, description: 'A link to the full text of the licence' }
          },
          extras: { required: %w[name last_update] }
        )
      end
    end
  end
end
