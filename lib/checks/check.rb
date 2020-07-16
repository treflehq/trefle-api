module Checks

  USER = User.find_by_email('andre@trefle.io')

  class Check

    def initialize(species_id)
      @species = Species.friendly.find(species_id)
    end

    def self.run(species_id)
      c = new(species_id)
      puts "[Checking #{self.class.to_s.humanize}] for [#{species_id}] Running..."
      c.run
    end

    def get_or_create_warning_for_record(record, params)
      r = RecordCorrection.where(
        record: record,
        warning_type: self.class.to_s
      ).first

      return if r&.pending_change_status?

      if r&.accepted_change_status?
        r.update(
          change_status: :pending,
          user: USER,
          source_type: :report,
          change_notes: [
            "Reopened on #{Time.zone.now}",
            r.change_notes
          ].compact.join("\n")
        )
      else
        RecordCorrection.create!(
          params.merge(
            record: record,
            source_type: :report,
            warning_type: self.class.to_s,
            user: USER
          )
        )
      end
    end

  end

  def self.run_all(species_id)
    enabled = [
      GenusSpecies,
      ScientificNameFormat,
      GenusName
    ].freeze

    enabled.each {|e| e.run(species_id) }
  end
end
