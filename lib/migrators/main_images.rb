module Migrators
  class MainImages

    def self.run
      Species.where(main_image_url: nil).where.not(images_count: 0).find_each do |s|
        next if s.images_count.zero?

        candidate = s.species_images.order(score: :desc).where(part: :habit)&.first&.image_url
        candidate ||= s.species_images.order(score: :desc)&.first&.image_url
        s.update_columns(main_image_url: candidate)
      end
    end

  end
end
