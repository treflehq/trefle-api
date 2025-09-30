module Rangeable
  extend ActiveSupport::Concern

  module ClassMethods
    def range_with(filtering_params)
      results = where(nil)
      filtering_params.each do |key, value|
        next unless value.present?

        start_val, end_val = value&.split(',')

        puts "Range with #{start_val&.strip&.inspect}, #{end_val&.strip&.inspect}"
        results = results.public_send(
          "range_by_#{key}",
          start_val&.blank? ? nil : start_val&.strip,
          end_val&.blank? ? nil : end_val&.strip
        )
      end
      results
    end
  end
end
