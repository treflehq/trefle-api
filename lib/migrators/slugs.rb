module Migrators
  class Slugs

    def self.run
      Species
        .where(slug: nil)
        .find_in_batches.each do |s|
          Species.where(id: s.map(&:id)).update(slug: nil)
        end
    end

  end
end
