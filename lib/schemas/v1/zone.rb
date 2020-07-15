module Schemas
  module V1
    module Zone
      def self.schema
        Helpers.object_of({
          id: { type: :integer },
          name: { type: :string },
          slug: { type: :string },
          tdwg_code: { type: :string },
          tdwg_level: { type: :integer },
          species_count: { type: :integer },
          links: Helpers.object_of({
            self: { type: :string },
            plants: { type: :string },
            species: { type: :string }
          }, extras: { required: %w[self plants species] })
        }, extras: { required: %w[id name slug links tdwg_code tdwg_level species_count] })
      end
    end
  end
end
