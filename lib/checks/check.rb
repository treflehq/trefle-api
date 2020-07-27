module Checks
  USER = User.find_by_email('andre@trefle.io')

  class Check

    attr_reader :species
    attr_reader :existing_check

    def initialize(species_id)
      @species = Species.friendly.find(species_id)
      @existing_check = RecordCorrection.where(
        record: @species,
        warning_type: self.class.to_s
      ).first
    end

    # This is the generic acceptance
    def accept!(user_id = nil)
      return unless @existing_check.pending_change_status?
      return unless @existing_check.record_type == 'Species'

      if @existing_check.deletion_change_type?
        @existing_check.record.destroy!
        @existing_check.update(
          accepted_by: user_id,
          change_status: :accepted
        )
      else
        correction = JSON.parse(@existing_check.correction_json)
        i = ::Ingester::Species.new(correction, species_id: @existing_check.record_id)
        res = i.ingest!
        if res[:valid]
          @existing_check.update(
            accepted_by: user_id,
            change_status: :accepted
          )
        else
          @existing_check.update(
            notes: [
              @existing_check.notes,
              "Unable to accept, #{res[:errors].join(', ')}"
            ].compact.join("\n")
          )
        end
      end
    end

    def self.run(species_id)
      c = new(species_id)
      puts "[Checking #{self.class.to_s.humanize}] for [#{species_id}] Running... (Existing check is #{c.existing_check.inspect})"
      result = c.run
      puts "[Checking #{self.class.to_s.humanize}] for [#{species_id}] Result -> #{result.inspect}..."

      c.close_and_resolve! if result.nil? && c.existing_check
      c
    end

    def close_and_resolve!
      @existing_check.resolve! if @existing_check&.pending_change_status?
    end

    protected

    def log(str)
      Rails.logger.warn "[Check #{self.class.to_s.humanize}][#{@species&.slug || 'unknown-species'}] #{str}"
    end

    def get_or_create_warning_for_record(params, correction = nil)
      return if @existing_check&.reload&.pending_change_status?

      if correction
        result = Ingester::Species.new(correction, dry_run: true, species_id: @species.id).ingest!

        pp result
        params[:change_notes] = result[:changes].to_json
        params[:correction_json] = correction.to_json
      end

      if @existing_check&.accepted_change_status?
        @existing_check.update! report_params(params)
      else
        RecordCorrection.create! report_params(params)
      end
    end

    def report_params(params)
      params[:notes] = @existing_check ? [@existing_check.notes, "Reopened on #{Time.zone.now}", params[:notes]].compact.join("\n") : params[:notes]

      {
        change_status: :pending,
        record: @species,
        source_type: :report,
        warning_type: self.class.to_s,
        user: USER
      }.merge(params)
    end

  end

  def self.run_all(species_id)
    enabled = [
      GenusSpecies,
      ScientificNameFormat,
      GenusName,
      NameAcceptance
    ].freeze

    enabled.each {|e| e.run(species_id) }
  end
end
