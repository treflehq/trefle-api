module Checks
  class ScientificNameFormat < Check

    def run
      good_name = ::Utils::ScientificName.format_name(@species.scientific_name, @species.author)

      return unless good_name != @species.scientific_name

      get_or_create_warning_for_record(
        {
          notes: "Species scientific name '#{@species.scientific_name}' seems not well formatted (expected #{good_name})"
        },
        { scientific_name: good_name }
      )
    end

  end
end
