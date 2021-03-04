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
      link&.gsub('http://', 'https://')&.gsub(' ', '%20')
    end
  end
end
