# Seeds the upstream licence of each foreign source (#318), verified
# 2026-09-07. Only sources with a confirmed licence are seeded here — every
# other source (IPNI, PlantNet, pfaf, flora_*...) stays NULL, never guessed.
#
# Never creates a ForeignSource: it seeds a licence onto a row that already
# exists, and reports the slugs it could not find instead of passing over them.
# Matching is case-insensitive because the stored casing is not uniform.
module Migrators
  class SourceLicences

    CC_BY_4_0 = {
      licence: 'CC-BY-4.0',
      licence_url: 'https://creativecommons.org/licenses/by/4.0/'
    }.freeze

    LICENCES = {
      'powo' => CC_BY_4_0,
      'gbif' => CC_BY_4_0,
      'wfo' => {
        licence: 'CC0-1.0',
        licence_url: 'https://creativecommons.org/publicdomain/zero/1.0/'
      },
      'usda' => {
        licence: 'Public domain (US Gov)',
        licence_url: 'https://www.usa.gov/government-works'
      }
    }.freeze

    # Slug casing is not consistent in foreign_sources -- WFO and IPNI are
    # stored upper-case, everything else lower-case -- so an exact match
    # silently skipped WFO and left the biggest taxonomic source without its
    # licence in production. Match case-insensitively, and say what was missed
    # rather than returning as if all four had been seeded.
    def self.run
      seeded = []
      missing = []

      LICENCES.each do |slug, attrs|
        fs = ForeignSource.where('lower(slug) = ?', slug.downcase).first

        if fs.nil?
          missing << slug
          next
        end

        fs.update!(attrs)
        seeded << fs.slug
      end

      Rails.logger.warn("[SourceLicences] no foreign_source for #{missing.join(', ')}") if missing.any?

      { seeded: seeded, missing: missing }
    end

  end
end
