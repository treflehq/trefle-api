module Checks
  class Check

    def self.run
      c = new
      puts "[Check #{self.class.to_s.humanize}] Running..."
      c.run
    end

    def get_or_create_warning_for_record(record, params)
      RecordCorrection.where(record: record, warning_type: self.class.to_s).first_or_create(params)
    end
  end

  def self.run_all
    [
      GenusSpecies
    ].each(&:run)
  end
end
