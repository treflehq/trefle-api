module Checks
  class ScientificNameFormat < Check

    def run

      good_name = ::Utils::ScientificName.format_name(@species.scientific_name, @species.author)

      return unless good_name != @species.scientific_name

      get_or_create_warning_for_record(@species, {
        notes: "Species scientific name '#{@species.scientific_name}' seems not well formatted (expected #{good_name})",
        change_type: :update,
        correction_json: {
          scientific_name: good_name
        }.to_json
      })
    end

  end
end
