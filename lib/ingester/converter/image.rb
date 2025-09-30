require 'httparty'
require 'colorize'

# Will convert measurement like fields
module Ingester
  module Converter
    class Image

      # Will add images @TODO
      def self.resolve!(_hash)
        {}
        # return {} unless hash[:image_url]

        # {
        #   species_images_attributes: hash[:image_url].split('|').map do |i|
        #     { image_url: i }
        #   end
        # }
      end
    end
  end
end
