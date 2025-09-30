module Migrators
  class UpdateCorrectionSpeciesReferences

    def self.run
      ::RecordCorrection.pending_change_status.each do |rc|
        rc.update_scientific_name_references
      end
      true
    end
  end
end
