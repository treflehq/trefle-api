# Fills the reuse terms of every species image (licence, licence_url,
# author, commercial_use_allowed, thumbnail_url) from its copyright and URL,
# with the parser new rows go through (ImageLicence, via SpeciesImage's
# before_save). Rows already holding the derived values are left alone, so a
# second run writes nothing. Each write rechecks the live row: an image whose
# copyright or URL changed since it was read is skipped and counted.
# Dry run by default.
module Migrators
  class ImageLicences

    BATCH_SIZE = 5_000
    COLUMNS = ImageLicence::FIELDS.map(&:to_s).freeze

    Result = Struct.new(
      :scanned, :to_update, :updated, :skipped_changed, :unchanged,
      :by_licence, :commercial_use_allowed, :with_author, :with_thumbnail,
      :unrecognised_copyrights,
      keyword_init: true
    ) do
      def to_h
        super.transform_keys(&:to_s)
      end
    end

    def self.run(dry_run: true)
      result = Result.new(
        scanned: 0, to_update: 0, updated: 0, skipped_changed: 0, unchanged: 0,
        by_licence: Hash.new(0), commercial_use_allowed: Hash.new(0),
        with_author: 0, with_thumbnail: 0, unrecognised_copyrights: Hash.new(0)
      )

      ::SpeciesImage.select(:id, :image_url, :copyright, *COLUMNS).find_in_batches(batch_size: BATCH_SIZE) do |images|
        changes = images.filter_map {|image| tally(image, result) }
        result.to_update += changes.size
        result.unchanged += images.size - changes.size
        next if dry_run || changes.empty?

        written = write(changes)
        result.updated += written
        result.skipped_changed += changes.size - written
      end

      Rails.logger.info("[ImageLicences]#{' DRY RUN' if dry_run} #{result.to_h.except('unrecognised_copyrights')}")
      result
    end

    # Counts what the image will hold; returns [image, derived] when that
    # differs from what it holds now.
    def self.tally(image, result)
      derived = ImageLicence.derive(copyright: image.copyright, image_url: image.image_url)
      result.scanned += 1
      result.by_licence[derived[:licence] || 'unknown'] += 1
      result.commercial_use_allowed[derived[:commercial_use_allowed].inspect] += 1
      result.with_author += 1 if derived[:author]
      result.with_thumbnail += 1 if derived[:thumbnail_url]
      result.unrecognised_copyrights[copyright_pattern(image.copyright)] += 1 if derived[:licence].nil?

      current = ImageLicence::FIELDS.index_with {|f| image[f] }
      current == derived ? nil : [image, derived]
    end

    # The copyright with its per-image parts (date, author) masked, so the
    # report lists the shapes left unread rather than every photographer.
    def self.copyright_pattern(copyright)
      copyright.to_s.sub(/\ATaken .+ by .+ \((?=[^()]*\)\z)/, 'Taken <date> by <author> (')[0, 120]
    end

    # One UPDATE per batch. The join on the copyright and URL that were read
    # is the live-state check: a row edited meanwhile matches nothing.
    # No `squish` on this SQL: it would also collapse the double spaces inside
    # the quoted copyrights ("Vargas  A Lorenzo"), and those rows would never
    # match (43 in the 2026-10-13 dump).
    def self.write(changes)
      conn = ::SpeciesImage.connection
      rows = changes.map do |image, derived|
        values = [image.id, image.copyright, image.image_url, *ImageLicence::FIELDS.map {|f| derived[f] }]
        "(#{values.map {|v| conn.quote(v) }.join(', ')})"
      end

      conn.update(<<~SQL)
        UPDATE species_images AS i SET
          licence = v.licence, licence_url = v.licence_url, author = v.author,
          commercial_use_allowed = v.commercial_use_allowed::boolean,
          thumbnail_url = v.thumbnail_url, updated_at = NOW()
        FROM (VALUES #{rows.join(', ')})
          AS v(id, copyright, image_url, licence, licence_url, author, commercial_use_allowed, thumbnail_url)
        WHERE i.id = v.id::bigint
          AND i.copyright IS NOT DISTINCT FROM v.copyright
          AND i.image_url = v.image_url
      SQL
    end

    private_class_method :tally, :copyright_pattern, :write

  end
end
