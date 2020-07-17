module Checks
  class GenusSpecies < Check

    def run
      return unless @species.scientific_name.split(' ').length <= 1

      get_or_create_warning_for_record(
        @species,
        {
          notes: "Specie #{@species.scientific_name} is more likely a genus",
          change_type: :deletion
        }
      )
    end

  end
end
