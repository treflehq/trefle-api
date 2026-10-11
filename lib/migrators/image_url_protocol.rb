# Protocol-relative image links ("//upload.wikimedia.org/...") came in with
# the Wikipedia crawl. They only resolve inside a browser page; an API
# client gets a path with no scheme. They become https. A species that
# already holds the https twin of a relative link loses the relative one
# (the pair is unique on image_url + species_id). Replayable; dry run by
# default (#419).
module Migrators
  class ImageUrlProtocol

    Result = Struct.new(:images, :main_images, :twins_removed, keyword_init: true)

    def self.run(dry_run: true)
      images = ::SpeciesImage.where("image_url LIKE '//%'")
      mains = ::Species.where("main_image_url LIKE '//%'")
      result = Result.new(images: images.count, main_images: mains.count, twins_removed: twin_ids.size)

      unless dry_run
        result.twins_removed = ::SpeciesImage.where(id: twin_ids).delete_all
        images.update_all("image_url = 'https:' || image_url") # rubocop:disable Rails/SkipsModelValidations
        mains.update_all("main_image_url = 'https:' || main_image_url") # rubocop:disable Rails/SkipsModelValidations
      end

      Rails.logger.info("[ImageUrlProtocol]#{' DRY RUN' if dry_run} #{result.to_h}")
      result
    end

    def self.twin_ids
      ::SpeciesImage.connection.select_values(<<~SQL.squish)
        SELECT r.id FROM species_images r
        JOIN species_images t ON t.species_id = r.species_id AND t.image_url = 'https:' || r.image_url
        WHERE r.image_url LIKE '//%'
      SQL
    end
    private_class_method :twin_ids

  end
end
