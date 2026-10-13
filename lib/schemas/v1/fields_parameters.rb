module Schemas
  module V1
    # The `fields` query parameter (SparseFieldsets), one component per set
    # of valid fields, published with the other shared parameters
    # (Parameters.all). The lists come straight from the serializers, so a
    # key added to one lands in the published document.
    module FieldsParameters
      def self.all
        {
          fields_species_list: fields(
            ::SpeciesListSerializer,
            'On a list, any key of the species detail can be asked for, groups included (`growth`, `flower`, `specifications`...), ' \
            'so the traits of a page come in one call; the rows then follow the species detail schema, restricted to those keys. ' \
            '`synonyms` stays on the detail (`links.synonyms`). With a field that embeds a collection per row ' \
            "(#{::SparseFieldsets::EMBEDDED_COLLECTIONS.join(', ')}), `per_page` is at most " \
            "#{::SparseFieldsets::EMBEDDED_COLLECTIONS_MAX_PER_PAGE}.",
            example: 'scientific_name,common_name,growth'
          ),
          fields_species: fields(::SpeciesSerializer, nil, example: 'scientific_name,growth,flower'),
          fields_plant: fields(::PlantSerializer, nil, example: 'common_name,main_species')
        }
      end

      def self.fields(serializer, extra, example:)
        valid = serializer.field_names.sort
        {
          name: 'fields', in: :query, required: false, style: :form, explode: false,
          description: ['The keys of the payload to return, separated by commas; `id` and `slug` always come. A key is a top-level ' \
                        'one: a group (`growth`) comes whole. An unknown key answers 400 with the valid ones.', extra,
                        "Valid keys: #{valid.map {|field| "`#{field}`" }.join(', ')}."].compact.join(' '),
          schema: { type: :array, items: { type: :string, enum: valid } },
          example: example.split(',')
        }
      end
    end
  end
end
