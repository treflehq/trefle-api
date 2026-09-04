require 'httparty'

module Migrators
  class ImagesFixer

    def self.run(species_id)
      sp = Species.friendly.find(species_id)
      return if sp.nil?

      return if sp.species_images.count.zero? && sp.main_image_url.nil?

      unless sp.main_image_url.nil?
        sp.main_image_url = sp.main_image_url.gsub('bs.floristic.org', 'bs.plantnet.org')
        sp.main_image_url = HTTParty.get(uri_for(sp.main_image_url)).ok? ? uri_for(sp.main_image_url) : nil
      end

      filter_species_images!(sp)

      if sp.main_image_url.nil?
        candidate = sp.species_images.order(score: :desc)&.reload&.first&.image_url
        sp.main_image_url = uri_for(candidate)
      end
      sp.save
    end

    def self.filter_species_images!(sp)
      sp.species_images.each do |si|
        si.image_url = si.image_url.gsub('bs.floristic.org', 'bs.plantnet.org')
        if HTTParty.get(uri_for(si.image_url)).ok?
          si.image_url = uri_for(si.image_url)
        else
          si.delete
        end
      end
    end

    def self.uri_for(link)
      link = link&.gsub(%r{^//}, 'https://')&.gsub('http://', 'https://')&.gsub(' ', '%20')
      return link if link.nil?

      # Some crawled URLs (POWO asset paths in particular) carry unescaped
      # non-ASCII characters (accented author names). URI.parse/HTTParty
      # raise URI::InvalidURIError on those, so percent-encode them here
      # rather than leaving it to the caller.
      URI::DEFAULT_PARSER.escape(link, /[^\x00-\x7F]/)
    end
  end
end
