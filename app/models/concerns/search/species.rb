module Search
  module Species
    extend ActiveSupport::Concern

    # Fields searched by /api/v1/species/search and /api/v1/plants/search.
    #
    # The `*_exact` entries are lowercased copies of the names indexed as
    # plain keywords (see #additional_search_data): an exact, case-insensitive
    # match on any common name, in any language, or on the scientific name
    # scores the same for every species (no stemming, no field-length
    # normalisation) and is boosted far above the analyzed fields, so it
    # lands at the top instead of being drowned by species whose names merely
    # contain the query word (#438). The remaining fields keep the word and
    # fuzzy matching through their `.analyzed` sub-field.
    SEARCH_FIELDS = [
      { 'common_names_exact^500' => :exact },
      { 'scientific_name_exact^400' => :exact },
      'common_name^10',
      'common_names^8',
      'scientific_name^5',
      'synonyms^3',
      'author',
      'genus',
      'family',
      'family_common_name',
      'distributions'
    ].freeze

    included do

      searchkick(
        word_start: %w[
          scientific_name
          common_name
          common_names
          synonyms
          distributions
          author
          genus_name
          family_name
          family_common_name
        ],
        case_sensitive: false,
        callbacks: :queue,
        index_prefix: 'trefle_2'
      )
    end

    class_methods do
      # Normalises a query (or an indexed name) for the `*_exact` keyword
      # fields. Searchkick queries those with the `keyword` analyzer, which
      # does not lowercase, so both the indexed values and the incoming
      # query go through this to agree on case and whitespace.
      def search_term(value)
        value.to_s.squish.downcase
      end
    end

    # A hidden record (Species::HIDDEN_REASONS) has no document: reindexing
    # it removes the one it had.
    def should_index?
      !hidden?
    end

    def search_data
      attributes.deep_symbolize_keys.merge(additional_search_data)
    end

    def additional_search_data
      {
        duration: duration.to_a, # We override the flags to have the string and not the binary flag
        propagated_by: propagated_by.to_a,
        growth_months: growth_months.to_a,
        bloom_months: bloom_months.to_a,
        fruit_months: fruit_months.to_a,
        flower_color: flower_color.to_a,
        fruit_color: fruit_color.to_a,
        foliage_color: foliage_color.to_a,
        edible_part: edible_part.to_a,

        synonyms: synonyms.pluck(:name).uniq,
        distributions: distributions,
        common_names: common_names_names,
        common_names_exact: exact_tokens([common_name, *common_names_names]),
        scientific_name_exact: exact_tokens([scientific_name]).first
      }
    end

    # We generate a hash of common names per lang
    def common_names_names
      common_names.pluck(:name).uniq
    end

    # We generate a hash of common names per lang
    # @TODO
    def common_names_per_lang
      common_names.pluck(:lang).uniq.map do |lang|
        [
          lang || 'en',
          common_names.where(lang: lang).pluck(:name)
        ]
      end.to_h
    end

    def distributions
      zones.pluck(:name)
    end

    private

    def exact_tokens(values)
      values.map {|v| self.class.search_term(v).presence }.compact.uniq
    end
  end
end
