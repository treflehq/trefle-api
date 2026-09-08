# Seeds the upstream licence of each foreign source (#318), verified
# 2026-09-07. Only sources with a confirmed licence are seeded here — every
# other source (IPNI, PlantNet, pfaf, flora_*...) stays NULL, never guessed.
#
# Matches by slug only, and never creates a ForeignSource: `db/botanic_seeds.rb`
# (the tracked seed data) has no WFO entry, so if production hasn't crawled a
# WFO-linked species yet, that row doesn't exist and this run no-ops for it —
# safe to re-run once it does.
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

    def self.run
      LICENCES.each do |slug, attrs|
        fs = ForeignSource.find_by(slug: slug)

        next unless fs

        fs.update!(attrs)
      end
    end

  end
end
