module Migrators
  class Families

    def self.run
      Family.where(division_order: nil).map do |f|

      end
    end

  end
end
