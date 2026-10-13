module Scopes
  module Species
    extend ActiveSupport::Concern

    # Public filter/order/range key => real column, for the couple of keys
    # where the public API name doesn't match storage (here: `image_url` is
    # exposed publicly but the column is `main_image_url`). The AR-backed
    # scopes below translate through this map; so does the Searchkick path
    # (Api::ApiController#search_params via `field_aliases:`) -- one mapping
    # instead of two lists that can drift apart again (#280).
    FIELD_ALIASES = {
      'image_url' => 'main_image_url'
    }.freeze

    class_methods do
      # Closed vocabularies of the species filters (Filterable#filter_vocabulary):
      # a value outside them answers 400 instead of silently matching the
      # wrong rows. Enums (status, rank, sexuality...), bitmask flags (duration,
      # colours, months, edible_part), the establishment of a distribution, and
      # the free-text columns traits.yml closes with allowed_values
      # (nitrogen_fixation).
      def filter_vocabularies
        @filter_vocabularies ||= begin
          vocabularies = defined_enums.transform_values(&:dup)
          active_flags.each {|name, flag| vocabularies[name.to_s] = flag.maps.keys.map(&:to_s) }
          vocabularies['establishment'] = ::SpeciesDistribution.establishments.dup
          Traits.fields.each do |name, field|
            vocabularies[name] ||= field['allowed_values'].map(&:to_s) if field.is_a?(Hash) && field['allowed_values']
          end
          vocabularies.freeze
        end
      end
    end

    included do # rubocop:todo Metrics/BlockLength

      Api::V1::SpeciesController::FILTERABLE_FIELDS.each do |field|
        # scope "filter_by_#{field}".to_sym, ->(v) { where(field => v) }
        scope "filter_by_#{field}".to_sym, lambda {|v|
          ::Species::COLUMN_TYPES[field] == :string ? where("lower(#{field}) IN (?)", [*v].map(&:to_s).map(&:downcase)) : where(field => v)
        }
      end

      Api::V1::SpeciesController::FILTERABLE_NOT_FIELDS.each do |field|
        scope "filter_not_by_#{field}".to_sym, lambda {|value|
          values = [*value]
          if values.compact.empty?
            # filter_not[field]=null means "only records where the field is set"
            where.not(field => nil)
          elsif ::Species::COLUMN_TYPES[field] == :string
            coll = where.not("lower(#{field}) IN (?)", values.compact.map(&:to_s).map(&:downcase))
            coll = coll.or(where(field => nil)) unless values.include?(nil)
            coll
          else
            coll = where.not(field => values)
            coll = coll.or(where(field => nil)) unless values.include?(nil)
            coll
          end
        }
      end

      ::Species.active_flags.each_key do |flag|
        scope "filter_not_by_#{flag}".to_sym, lambda {|value|
          flagger = ::Species.active_flags[flag]
          if value && value.first
            values = flagger.maps.keys - [*value].map(&:to_sym)

            if values == flagger.maps.keys
              where.not(flag => 0).where.not(flag => nil)
            else
              int_val = flagger.to_i(values)
              where.not("species.#{flag} & #{int_val} > 0")
            end
          else
            where.not(flag => 0).where.not(flag => nil)
          end
        }
      end

      # Associations overrides
      scope :filter_by_establishment, ->(v) { joins(:species_distributions).where(species_distributions: { establishment: v }).distinct }

      # Binary flags overrides
      scope :filter_by_duration, ->(v) { where_duration(*v) }
      scope :filter_not_by_duration, ->(_v) { where.not(duration: 0).where.not(duration: nil) }
      scope :filter_by_growth_months, ->(v) { where_growth_months(*v) }
      scope :filter_not_by_growth_months, ->(_v) { where.not(growth_months: 0).where.not(growth_months: nil) }
      scope :filter_by_bloom_months, ->(v) { where_bloom_months(*v) }
      scope :filter_not_by_bloom_months, ->(_v) { where.not(bloom_months: 0).where.not(bloom_months: nil) }
      scope :filter_by_fruit_months, ->(v) { where_fruit_months(*v) }
      scope :filter_not_by_fruit_months, ->(_v) { where.not(fruit_months: 0).where.not(fruit_months: nil) }
      scope :filter_by_flower_color, ->(v) { where_flower_color(*v) }
      scope :filter_not_by_flower_color, ->(_v) { where.not(flower_color: 0).where.not(flower_color: nil) }
      scope :filter_by_foliage_color, ->(v) { where_foliage_color(*v) }
      scope :filter_not_by_foliage_color, ->(_v) { where.not(foliage_color: 0).where.not(foliage_color: nil) }
      scope :filter_by_fruit_color, ->(v) { where_fruit_color(*v) }
      scope :filter_not_by_fruit_color, ->(_v) { where.not(fruit_color: 0).where.not(fruit_color: nil) }
      scope :filter_by_edible_part, ->(v) { where_edible_part(*v) }
      # scope :filter_not_by_edible_part, lambda {|value|
      #   if value
      #     values = ::Species.edible_parts.maps.keys - [*value].map(&:to_sym)

      #     if values == ::Species.edible_parts.maps.keys
      #       where.not(edible_part: [0, nil])
      #     else
      #       int_val = ::Species.edible_parts.to_i(values)
      #       where.not("species.edible_part & #{int_val} > 0")
      #     end
      #   else
      #     where.not(edible_part: [0, nil])
      #   end
      # }
      scope :filter_not_by_image_url, ->(_v) { where.not(FIELD_ALIASES['image_url'] => nil) }

      # Ranges: `range[field]=min,max`, inclusive on both sides, either side
      # optional, bounds parsed as decimals (see Rangeable). One generated
      # scope per RANGEABLE_FIELDS entry instead of a hand-kept list that had
      # drifted (truncated bounds, exclusive upper bound, range_by_year
      # defined twice).
      Api::V1::SpeciesController::RANGEABLE_FIELDS.each do |field|
        scope "range_by_#{field}".to_sym, ->(min, max) { where_in_range(field, min, max) }
      end

      # Search
      scope :database_search, lambda {|q|
        where('full_token ILIKE ?', "%#{q}%")
      }

      # plants
      scope :plants, -> { where(main_species_id: nil) }
      scope :vegetable, ->(_v) { where(vegetable: true) }
      scope :edible, ->(_v) { where.not(edible_part: [0, nil]) }

    end
  end
end
