require 'httparty'
require 'colorize'

# Will convert measurement like fields
module Ingester
  module Converter
    class CommonName

      # Will add images @TODO
      def self.resolve!(hash)
        return {} unless hash[:common_name]

        {
          common_names_attributes: hash[:common_name].split('|').map do |i|
            cname = ::CommonName.where(name: i).first
            next nil if cname

            { name: i }
          end.compact
        }
      end
    end
  end
end
