require 'httparty'

module Migrators
  class ImagesFixer

    def self.run(species_id)
      sp = Species.friendly.find(species_id)
      return if sp.nil?

      return if sp.species_images.count.zero? && sp.main_image_url.nil?

      sp.main_image_url = nil unless HTTParty.get(sp.main_image_url).ok?

      s.species_images.each do |si|
        si.delete unless HTTParty.get(sp.image_url).ok?
      end

      if sp.main_image_url.nil?
        candidate = sp.species_images.order(score: :desc)&.reload&.first&.image_url
        sp.main_image_url = candidate
      end
      sp.save
    end
  end

end