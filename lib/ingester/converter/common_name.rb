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
          # The column holds the species' usual English name and is what the
          # API exposes; the records hold every vernacular name we know. Both
          # are fed from the same key, the column taking the first name — a
          # source sending "Okra|Bonnie Green" means the first one is the
          # common one. Without this the column was unreachable: a source could
          # send common_name and see it silently dropped.
          common_name: common_name_arrays.first,
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
