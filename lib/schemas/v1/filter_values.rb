module Schemas
  module V1
    # The schema of the value of one `filter[field]` / `filter_not[field]` key
    # (Schemas::V1::Parameters): a string, with the accepted values listed
    # when the field has a closed vocabulary (Filterable#filter_vocabulary,
    # the same list the API checks a value against), and an example that
    # makes sense for the field instead of the same one everywhere.
    #
    # Not an `enum`: a value may hold several comma-separated names
    # (`filter[flower_color]=red,yellow`), which an enum would refuse.
    module FilterValues
      # Keys of a closed vocabulary not listed here use the first accepted value.
      EXAMPLES = {
        'author' => 'L.',
        'bloom_months' => 'may,jun',
        'common_name' => 'tomato',
        'completion_ratio' => '100',
        'duration' => 'perennial',
        'edible_part' => 'fruits,leaves',
        'family_common_name' => 'Rose family',
        'family_name' => 'Rosaceae',
        'flower_color' => 'red,yellow',
        'foliage_color' => 'green',
        'fruit_color' => 'red',
        'fruit_months' => 'sep,oct',
        'genus_name' => 'Rosa',
        'growth_form' => 'Single Stem',
        'growth_habit' => 'Shrub',
        'growth_months' => 'apr,may',
        'growth_rate' => 'Rapid',
        'ligneous_type' => 'shrub',
        'nitrogen_fixation' => 'High',
        'scientific_name' => 'Rosa canina',
        'sexuality' => 'hermaphrodite',
        'tdwg_code' => 'FRA',
        'tdwg_level' => '3'
      }.freeze

      # model: the ActiveRecord class the values are checked against, if any.
      def self.schema(field, model, example: EXAMPLES[field])
        names = model&.filter_vocabulary_names(field)
        boolean = model&.columns_hash&.dig(field)&.type == :boolean
        description =
          if names then "One of: #{names.join(', ')}. Several, separated by commas, match any of them."
          elsif boolean then 'true or false (also yes/no, 1/0, on/off).'
          end
        example ||= boolean ? 'true' : names&.first
        { type: :string, description: description, example: example }.compact
      end
    end
  end
end
