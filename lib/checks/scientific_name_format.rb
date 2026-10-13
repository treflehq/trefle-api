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

    def accept!(user_id = nil)
      # change_notes is the dry-run diff of the correction, and it can be "{}"
      # when that dry run saw no name change: nothing to merge then.
      names = JSON.parse(@existing_check.change_notes.presence || '{}')['scientific_name']
      return super(user_id) if names.blank?

      before, after = names.map {|e| Species.find_by_scientific_name(e) }

      # If a species with a good name exists, we merge them together
      if after
        ::Utils::Merger.new([before.id], after.id).merge!
        @existing_check.update(record: after)
      end

      super(user_id)
    end
  end
end
