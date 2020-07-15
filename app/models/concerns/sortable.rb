module Sortable
  extend ActiveSupport::Concern

  module ClassMethods
    def sort_with(filtering_params)
      results = where(nil)
      filtering_params_hash = filtering_params.is_a?(Hash) ? filtering_params : filtering_params.to_unsafe_hash
      sort_hash = filtering_params_hash.map do |key, value|
        dir = value.to_s.underscore.strip == 'desc' ? :desc : :asc
        [key&.to_s&.strip&.downcase&.to_sym, dir]
      end.to_h
      results.order(sort_hash.merge(id: :asc))
    end
  end
end
