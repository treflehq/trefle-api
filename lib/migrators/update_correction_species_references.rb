module Migrators
  class UpdateCorrectionSpeciesReferences

    def self.run
      ::RecordCorrection.pending_change_status.each(&:update_scientific_name_references)
      true
    end
  end
end
