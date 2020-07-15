require 'httparty'
require 'colorize'

# Will convert measurement like fields
module Ingester
  module Converter
    class Genus

      class GenusException < IngesterException

      end

      # Will convert measurement like fields
      def self.resolve!(hash)
        genus_id = hash.dig(:genus_id)
        genus_name = hash.dig(:genus)

        return { genus_id: genus_id } if genus_id && ::Genus.find(genus_id)

        return {} unless genus_name

        genus = ::Genus.find_by_name(genus_name) || ::Genus.find_by_slug(genus_name.parameterize)
        return { genus_id: genus.id } if genus

        raise GenusException, "Unable to find a genus for #{genus_name}"
      end
    end
  end
end
