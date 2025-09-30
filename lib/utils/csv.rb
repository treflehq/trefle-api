require 'csv'

module Utils
  module Csv
    # Array of hashes to CSV file
    def self.array_to_csv(hashes, filename = nil, **opts)
      o = {
        encoding: 'UTF-8',
        write_empty_value: nil,
        col_sep: "\t"
      }.merge(opts)

      return false unless hashes.first

      column_names = hashes.first.keys

      s = CSV.generate do |csv|
        csv << column_names
        hashes.each {|x| csv << x.values }
      end

      File.write(filename, s) unless filename.blank?
      s
    end

    # CSV file to array of hashes
    def self.csv_to_array(filename, **opts)
      o = {
        headers: true,
        encoding: 'UTF-8',
        col_sep: "\t"
      }.merge(opts)
      data = CSV.read(filename, o)
      fdata = data.map.with_index do |sp, i|

        sp.to_h.transform_keys(&:parameterize).deep_symbolize_keys
      rescue StandardError => e
        pp sp.to_h
        puts "Error on line #{i}: #{e}"
        throw e

      end
      fdata
    end
  end
end
