module Checks
  class NameAcceptance < Check

    def run

      return unless @species.species_rank? || @species.ssp_rank? || @species.hybrid_rank?

      token = ::Utils::ScientificName.tokenize(@species.scientific_name)
      good_data = ::Resolver::Powo.resolve_hash(token)

      if good_data.nil?
        puts "[NameAcceptance][#{@species.scientific_name}] Species scientific name ('#{@species.scientific_name}') can't be found on GBIF or POWO"
        return get_or_create_warning_for_record(
          @species,
          {
            notes: "Species scientific name ('#{@species.scientific_name}') can't be found on GBIF or POWO",
            change_type: :deletion
          }
        )
      end

      puts "[NameAcceptance][#{@species.scientific_name}] Species scientific name is correct !" unless good_data[:scientific_name] != @species.scientific_name

      return unless good_data[:scientific_name] != @species.scientific_name

      ref_url = "http://powo.science.kew.org/taxon/#{good_data[:source_powo]}"

      return get_or_create_warning_for_record(
        @species,
        {
          notes: "According to POWO, species scientific name should be #{good_data[:scientific_name]} (ours is '#{@species.scientific_name}')",
          source_type: :external,
          source_reference: ref_url,
          change_type: :update
        },
        {
          scientific_name: good_data[:scientific_name],
          author: good_data[:author],
          bibliography: good_data[:bibliography]
        }
      )
    end

  end
end
