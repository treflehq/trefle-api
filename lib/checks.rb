module Checks
  # Runs every check that only relies on local data for one species.
  # Checks::NameAcceptance (external APIs) and Checks::SpeciesDuplicates
  # (whole-table scan) are heavier and must be scheduled on their own.
  def self.run_all(species_id)
    [Checks::GenusName, Checks::GenusSpecies, Checks::ScientificNameFormat, Checks::PlausibleValues].map do |check|
      check.run(species_id)
    end
  end
end
