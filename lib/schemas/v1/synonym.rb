module Schemas
  module V1
    module Synonym
      def self.schema
        Helpers.object_of({
          id: { type: :integer, description: 'An unique identifier' },
          name: { type: :string, description: 'The scientific name of the synonym' },
          author: { type: :string, nullable: true, description: 'The author of the synonym' },
          attached_to: {
            type: :string,
            nullable: true,
            description: 'The scientific name of the record this synonym is attached to: the species itself, or one of its autonyms ' \
                         '(e.g. "Quercus robur subsp. robur") when the synonym was recorded on the typical subspecies or variety'
          },
          sources: Helpers.schema_array_href(schema: 'source').merge(description: 'The sources this synonym was built from')
        }, extras: { required: %w[id name], description: 'A scientific name once applied to the species (or to one of its autonyms), with its author' })
      end
    end
  end
end
