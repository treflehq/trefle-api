module Schemas
  module V1
    # The query parameters the collection endpoints share, published under
    # `components.parameters` of the OpenAPI document and declared in the rswag
    # specs with `parameters :filter_species, :page` (spec/support/openapi_dsl.rb).
    #
    # `filter`, `filter_not`, `order` and `range` are objects keyed by field
    # (`filter[edible]=true&order[year]=desc`), which OpenAPI 3 calls
    # `style: deepObject`. Declared as bare objects, as they were up to 2.9.6, a
    # generated client serialises them as one `filter=...` string the server
    # never reads (#221). The allowed keys come straight from the controller
    # constants, so a field added to FILTERABLE_FIELDS lands in the published
    # document on the next `rake rswag:specs:swaggerize`, and an unknown key is
    # a 400 (Api::ApiController#permit_known_query_keys).
    module Parameters
      def self.all
        {
          page: page,
          per_page: per_page,
          q: search_query,
          zone_q: zone_search_query,
          **keyed_parameters(:species, ::Api::V1::SpeciesController),
          **keyed_parameters(:families, ::Api::V1::FamiliesController),
          **keyed_parameters(:genus, ::Api::V1::GenusController),
          **keyed_parameters(:zones, ::Api::V1::ZonesController),
          **keyed_parameters(:corrections, ::Api::V1::RecordCorrectionsController)
        }
      end

      def self.page
        {
          name: 'page', in: :query, required: false,
          description: "The page to fetch, starting at 1. `/species` and `/plants` cap it at #{::WithCachedCount::MAX_PAGE_DEPTH} " \
                       'and answer 400 beyond: narrow the results with a filter or a range instead of paging through the whole collection.',
          schema: { type: :integer, minimum: 1, default: 1 }
        }
      end

      def self.per_page
        {
          name: 'per_page', in: :query, required: false,
          description: "Items per page, #{::PerPage::DEFAULT} by default, at most #{::PerPage::MAX}. `limit` is accepted as an alias. " \
                       'Out of range or not an integer answers 400.',
          schema: { type: :integer, minimum: 1, maximum: ::PerPage::MAX, default: ::PerPage::DEFAULT }
        }
      end

      def self.search_query
        {
          name: 'q', in: :query, required: true,
          description: 'The text to search for: a scientific name, a common name, a synonym, an author, a genus or a family name',
          schema: { type: :string }, example: 'coconut'
        }
      end

      def self.zone_search_query
        {
          name: 'q', in: :query, required: false,
          description: 'Search zones by name (part of the name, case- and accent-insensitive). Exact matches come first.',
          schema: { type: :string }, example: 'Europe'
        }
      end

      # filter_<suffix>, filter_not_<suffix>, order_<suffix> and range_<suffix>
      # for the constants the controller defines.
      def self.keyed_parameters(suffix, controller)
        {
          "filter_#{suffix}": controller.const_defined?(:FILTERABLE_FIELDS, false) && filter(controller::FILTERABLE_FIELDS),
          "filter_not_#{suffix}": controller.const_defined?(:FILTERABLE_NOT_FIELDS, false) && filter_not(controller::FILTERABLE_NOT_FIELDS),
          "order_#{suffix}": controller.const_defined?(:ORDERABLE_FIELDS, false) && order(controller::ORDERABLE_FIELDS),
          "range_#{suffix}": controller.const_defined?(:RANGEABLE_FIELDS, false) && range(controller::RANGEABLE_FIELDS)
        }.select {|_name, parameter| parameter }
      end

      def self.filter(fields)
        deep_object(
          'filter', fields,
          description: 'Keep the records whose field equals the value: `filter[field]=value`. Several values separated by commas ' \
                       'match any of them (`filter[flower_color]=red,pink`). Boolean fields accept true, yes, 1, on, false, no, 0 and off. ' \
                       'One key per filterable field; an unknown key answers 400.',
          value: { type: :string, example: 'red,pink' }
        )
      end

      def self.filter_not(fields)
        deep_object(
          'filter_not', fields,
          description: 'Exclude the records whose field equals the value(s): `filter_not[field]=value1,value2`. ' \
                       '`null` excludes the records where the field is empty (`filter_not[edible_part]=null`). An unknown key answers 400.',
          value: { type: :string, example: 'null' }
        )
      end

      def self.order(fields)
        deep_object(
          'order', fields,
          description: 'Sort on the field, `asc` (default) or `desc`: `order[year]=desc`. Several keys sort on several fields, ' \
                       'in the order given. An unknown key answers 400.',
          value: { type: :string, enum: %w[asc desc], example: 'desc' }
        )
      end

      def self.range(fields)
        deep_object(
          'range', fields,
          description: 'Keep the records whose field lies between two bounds: `range[field]=min,max`, both inclusive. ' \
                       'Leave one side empty for an open bound (`range[maximum_height_cm]=1000,` or `,10`). Decimal and negative ' \
                       'bounds are accepted; a non-numeric bound or an unknown key answers 400.',
          value: { type: :string, example: '10,100' }
        )
      end

      def self.deep_object(name, fields, description:, value:)
        {
          name: name, in: :query, required: false, style: :deepObject, explode: true,
          description: description,
          schema: Helpers.object_of(fields.uniq.index_with { value }, extras: { additionalProperties: false })
        }
      end
    end
  end
end
