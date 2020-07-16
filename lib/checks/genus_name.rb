module Checks
  class GenusName < Check

    def run
      return if @species.scientific_name.split(' ')&.first == @species&.genus&.name

      good_name = [@species&.genus&.name, @species.scientific_name.split(' ').slice(1, 10)].flatten.join(' ')
      get_or_create_warning_for_record(@species, {
        notes: "Specie #{@species.scientific_name} genus don't match genus '#{@species&.genus&.name}', expected #{good_name}.",
        change_type: :update,
        correction_json: {
          scientific_name: good_name
        }.to_json
      })
    end

  end
end
