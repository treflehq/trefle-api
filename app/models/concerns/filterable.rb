module Filterable
  extend ActiveSupport::Concern

  module ClassMethods
    def filter_with(filtering_params)
      results = where(nil)
      filtering_params.each do |key, value|
        results = results.public_send("filter_by_#{key}", value.split(',').map{|e| convert_value(e) }.compact) if value.present?
      end
      results
    end

    def filter_not_with(filtering_params)
      results = where(nil)
      filtering_params.each do |key, value|
        vs = value.present? ? value.split(',').map{|e| convert_value(e) }.compact : nil
        results = results.public_send("filter_not_by_#{key}", vs)
      end
      results
    end

    def convert_value(value)
      case value.strip
      when 'true'
        true
      when 'false'
        false
      when 'null'
        nil
      else
        value.strip
      end
    end
  end
end
