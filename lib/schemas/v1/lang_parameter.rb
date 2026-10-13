module Schemas
  module V1
    # The `lang` query parameter of the species and plants endpoints
    # (CommonNameLocalization), published with the other shared parameters
    # (Parameters.all).
    module LangParameter
      def self.schema
        {
          name: 'lang', in: :query, required: false,
          description: 'An [ISO 639-1](https://en.wikipedia.org/wiki/List_of_ISO_639_language_codes) language code (`fr`, `de`, `es`...). ' \
                       '`common_name` is then the name of the species in that language: among its names in the language, the one ' \
                       'the most sources agree on (the first recorded on a tie). A species without a name in the language keeps its ' \
                       'English name. `common_name_lang` tells which language the name is in (`null` when the species has no common ' \
                       'name at all). `filter[common_name]` and `filter_not[common_name]` then match the names of that language, ' \
                       'ignoring case and accents (`filter[common_name]=tomate&lang=fr`); `filter[common_name]=null` keeps the ' \
                       'species without a name in it, `filter_not[common_name]=null` those with one. `order[common_name]` still ' \
                       'sorts on the English name. Without `lang`, `common_name` is the English name. A code no common name is ' \
                       'recorded in answers 400 with the accepted ones.',
          schema: { type: :string, pattern: '^[a-zA-Z]{2}$' }, example: 'fr'
        }
      end
    end
  end
end
