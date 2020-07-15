require 'httparty'
require 'colorize'

module Ingester
  class IngesterException < RuntimeError

  end

  def self.from_hash(hash, **options)
    ::Ingester::Species.new(hash, options).ingest!
  end

  def self.from_array(array, **options)
    array.map do |hash|
      ::Ingester::Species.new(hash, options).ingest!
    end
  end

  def self.from_file(filename, **options)
    data = JSON.parse(File.read(filename))
    data.is_a?(Array) ? from_array(data, options) : from_hash(data, options)
  end

  def self.from_csv(filename, **_options)
    data = csv_to_array(filename)
    # data.is_a?(Array) ? from_array(data, options) : from_hash(data, options)
  end
end
