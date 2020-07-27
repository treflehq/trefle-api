module Checks
  class NameAcceptance < Check

    def run
      return unless @species.species_rank? || @species.ssp_rank? || @species.hybrid_rank?

      token = ::Utils::ScientificName.tokenize(@species.scientific_name)
      good_data = ::Resolver::Powo.resolve_hash(@species.scientific_name)
      return if good_data && good_data[:scientific_name] == @species.scientific_name

      good_data ||= ::Resolver::Powo.resolve_hash(token)
      good_data ||= ::Resolver::Gbif.resolve_hash(token)

      if good_data.nil?
        log("Species scientific name ('#{@species.scientific_name}') can't be found on GBIF or POWO".red)
        return get_or_create_warning_for_record(
          {
            notes: "Species scientific name ('#{@species.scientific_name}') can't be found on GBIF or POWO",
            change_type: :deletion
          }
        )
      end

      log('Species scientific name is correct !'.green) unless good_data[:scientific_name] != @species.scientific_name

      return unless good_data[:scientific_name] != @species.scientific_name

      ref_url = "http://powo.science.kew.org/taxon/#{good_data[:source_powo]}"

      get_or_create_warning_for_record(
        {
          notes: "According to POWO, species scientific name should be #{good_data[:scientific_name]} (ours is '#{@species.scientific_name}')",
          source_type: :external,
          source_reference: ref_url,
          change_type: :update
        },
        {
          scientific_name: good_data[:scientific_name],
          rank: good_data[:rank],
          author: good_data[:author],
          bibliography: good_data[:bibliography]
        }.compact
      )
    end

    def accept!(user_id = nil)

      return super(user_id) if @existing_check.change_notes.blank?
      
      before, after = JSON.parse(@existing_check.change_notes).dig("scientific_name").map{|e| Species.find_by_scientific_name(e) }

      # If a species with a good name exists, we merge them together
      if after
        ::Utils::Merger.new([before.id], after.id).merge!
        @existing_check.update(record: after)
      end

      super(user_id)
    end

  end
end
