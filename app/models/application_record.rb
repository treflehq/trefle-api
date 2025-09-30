class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  class << self
    private

    def timestamp_attributes_for_create
      super << 'inserted_at'
    end

  end

end
