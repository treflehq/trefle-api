require 'httparty'
require 'colorize'

# Will convert measurement like fields
module Ingester
  module Converter
    class Source

      class SourceException < IngesterException

      end

      # Will add images @TODO
      def self.resolve!(hash)
        keys = hash.keys.filter {|e| e.to_s.starts_with?('source_') }

        return {} if keys.empty?

        fsp = keys.map do |k|
          source_name = k.to_s.strip.gsub(/^source_/, '')
          fs = ForeignSource.find_by(slug: source_name) || ForeignSource.find_by(name: source_name)

          fs ||= ForeignSource.create!(name: source_name)

          fsp = ForeignSourcesPlant.where(fid: hash[k.to_sym], foreign_source_id: fs.id)

          next nil if fsp.any?

          {
            fid: hash[k.to_sym],
            foreign_source_id: fs.id,
            last_update: Time.zone.now
          }
        end
        puts "[Converter][Source] Species.foreign_sources_plants_attributes = #{fsp.inspect}"

        {
          foreign_sources_plants_attributes: fsp.compact
        }
      end

    end
  end
end
