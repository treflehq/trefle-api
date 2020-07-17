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

    def get_or_create_warning_for_record(record, params, correction = nil)
      r = RecordCorrection.where(
        record: record,
        warning_type: self.class.to_s
      ).first

      return if r&.pending_change_status?

      if correction
        result = Ingester::Species.new(correction, dry_run: true, species_id: record.id).ingest!

        pp result
        params[:change_notes] = result[:changes].to_json
        params[:correction_json] = correction.to_json
      end

      if r&.accepted_change_status?
        r.update! report_params(r, record, params)
      else
        RecordCorrection.create! report_params(r, record, params)
      end
    end


    def report_params(report, record, params)
      changes_notes = report ? ["Reopened on #{Time.zone.now}", report.change_notes].compact.join("\n") : nil

      {
        change_status: :pending,
        record: record,
        source_type: :report,
        warning_type: self.class.to_s,
        user: USER,
        change_notes: changes_notes
      }.merge(params)
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
