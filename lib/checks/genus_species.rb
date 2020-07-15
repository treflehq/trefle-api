module Checks
  class GenusSpecies < Check

    def run
      length_q = "char_length(scientific_name) - char_length(REPLACE(scientific_name, ' ', ''))"
      sps = Species.select("id, #{length_q} as levels, scientific_name").where("#{length_q} = 0")
      sps.each do |sp|
        get_or_create_warning_for_record(sp, {
          notes: "Specie #{sp.scientific_name} is more likely a genus",
          change_type: :deletion
        })
      end
    end

  end
end
