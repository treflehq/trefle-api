module Search
  module Species
    extend ActiveSupport::Concern

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
        common_names: common_names_names
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
  end
end
