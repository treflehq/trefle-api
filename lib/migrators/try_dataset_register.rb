# Seeds the TRY dataset register from db/data/try_datasets.yml
# (treflehq/trefle-crawlers#26).
#
# Replayable: upserts on (dataset_id, reference), so re-running after the CSV
# is regenerated adds what is new and leaves the rest alone. It never deletes —
# a dataset dropping out of a later export does not un-owe its credit for the
# values already ingested from it.
module Migrators
  class TryDatasetRegister

    Result = Struct.new(:created, :updated, :unchanged, :without_reference, keyword_init: true)

    def self.run(path: TryDataset.register_path, dry_run: true)
      result = Result.new(created: 0, updated: 0, unchanged: 0, without_reference: 0)

      rows(path).each do |row|
        result.without_reference += 1 if row[:reference].blank?
        apply(row, result, dry_run)
      end

      Rails.logger.info("[TryDatasetRegister]#{' [dry-run]' if dry_run} created=#{result.created} " \
                        "updated=#{result.updated} unchanged=#{result.unchanged} " \
                        "without_reference=#{result.without_reference}")
      result
    end

    # YAML rather than CSV because .gitignore excludes *.csv across this repo,
    # to keep bulk crawler exports out of a public checkout. This register is
    # the opposite kind of file — the credit CC BY obliges us to publish — so
    # it is stored in a committed format instead of forced past that rule.
    #
    # The exports carry non-UTF-8 bytes in their reference strings; they are
    # transcoded when the register is generated, not here. A bad byte should
    # fail loudly rather than seed mojibake into an attribution.
    def self.rows(path)
      YAML.safe_load_file(path).map do |row|
        {
          dataset_id: row['dataset_id'].to_i,
          dataset_name: row['dataset_name'].presence,
          contributor: row['contributor'].presence,
          reference: row['reference'].presence
        }
      end
    end

    def self.apply(row, result, dry_run)
      existing = TryDataset.find_by(dataset_id: row[:dataset_id], reference: row[:reference])

      if existing.nil?
        result.created += 1
        TryDataset.create!(row) unless dry_run
      elsif existing.dataset_name == row[:dataset_name] && existing.contributor == row[:contributor]
        result.unchanged += 1
      else
        result.updated += 1
        existing.update!(row) unless dry_run
      end
    end

  end
end
