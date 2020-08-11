require 'httparty'
require 'colorize'

# Will convert measurement like fields
module Ingester
  module Converter
    class CommonName

      # Will add common names @TODO
      def self.resolve!(hash)
        return {} unless hash[:common_name]

        common_name_arrays = if hash[:common_name].is_a?(Array)
                               hash[:common_name]
                             else
                               hash[:common_name].split('|')
                             end

        {
          common_names_attributes: common_name_arrays.map do |i|
            cname = ::CommonName.where(name: i).first
            next nil if cname

            { name: i }
          end.compact
        }
      end
    end
  end
end
