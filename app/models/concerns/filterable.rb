module Filterable
  extend ActiveSupport::Concern

  module ClassMethods
    def filter_with(filtering_params)
      results = where(nil)
      filtering_params.each do |key, value|
        results = results.public_send("filter_by_#{key}", value.split(',').map(&:strip).compact) if value.present?
      end
      results
    end

    def filter_not_with(filtering_params)
      results = where(nil)
      filtering_params.each do |key, value|
        # rubocop:todo Style/NestedTernaryOperator
        vs = value.present? ? value.split(',').map(&:strip).compact.map {|e| e == 'null' ? nil : e } : nil
        # rubocop:enable Style/NestedTernaryOperator
        results = results.public_send("filter_not_by_#{key}", vs)
      end
      results
    end
  end
end
