# The first import (2022-12) wrote the USDA PLANTS English common names
# ("Bliss' buckwheat", "Nakedstem hawksbeard") with no language: 12,975 rows,
# ASCII only. Anything that reads a language — the English search token in
# Species#regenerate_tokens!, the per-language display — skips them. They get
# `en`. A row whose record already has the same name under `en` (GBIF brought
# most of them back with a language) is a duplicate once tagged, and is
# dropped; the tagged row stays. Likewise among the untagged rows themselves:
# of several with the same name on one record, the lowest id is kept.
#
# Only rows created before 2023 and matching ^[ -~]+$ qualify. The empty-lang
# rows created in 2026 are multilingual ("Atlas-Mohn", "mozzevel'nik") and are
# left alone, counted so the dry run shows them. Replayable; dry run by
# default.
module Migrators
  class CommonNameMissingLanguage

    CUTOFF = Time.utc(2023, 1, 1)
    ASCII = '^[ -~]+$'.freeze

    Result = Struct.new(:tagged_en, :duplicates_removed, :left_recent, :left_non_ascii, keyword_init: true)

    def self.scope
      ::CommonName.where(lang: [nil, '']).where(created_at: ...CUTOFF).where('name ~ ?', ASCII)
    end

    # Rows whose record already carries the same name (case-insensitive) in English.
    def self.duplicates
      scope.where(<<~SQL.squish)
        EXISTS (SELECT 1 FROM common_names o
                WHERE o.record_type = common_names.record_type AND o.record_id = common_names.record_id
                  AND lower(o.name) = lower(common_names.name) AND o.lang = 'en')
      SQL
    end

    # Untagged rows repeating another untagged row of the same record and name
    # (case-insensitive): all but the lowest id.
    def self.internal_duplicates
      scope.where(<<~SQL.squish)
        EXISTS (SELECT 1 FROM common_names o
                WHERE o.record_type = common_names.record_type AND o.record_id = common_names.record_id
                  AND lower(o.name) = lower(common_names.name) AND (o.lang IS NULL OR o.lang = '')
                  AND o.created_at < '#{CUTOFF.iso8601}' AND o.name ~ '#{ASCII}' AND o.id < common_names.id)
      SQL
    end

    def self.duplicate_ids
      (duplicates.pluck(:id) + internal_duplicates.pluck(:id)).uniq
    end

    def self.run(dry_run: true)
      empty = ::CommonName.where(lang: [nil, ''])
      result = Result.new(
        tagged_en: scope.where.not(id: duplicate_ids).count,
        duplicates_removed: ::CommonName.where(id: duplicate_ids).count,
        left_recent: empty.where(created_at: CUTOFF..).count,
        left_non_ascii: empty.where(created_at: ...CUTOFF).where.not('name ~ ?', ASCII).count
      )

      unless dry_run
        result.duplicates_removed = ::CommonName.where(id: duplicate_ids).delete_all
        result.tagged_en = scope.update_all(lang: 'en') # rubocop:disable Rails/SkipsModelValidations
      end

      Rails.logger.info("[CommonNameMissingLanguage]#{' DRY RUN' if dry_run} #{result.to_h}")
      result
    end

  end
end
