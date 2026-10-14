# Reads the reuse terms of a species image out of what the crawlers stored:
# the free-text `copyright` and the image URL. One explicit pattern per
# source; anything else yields nil, never a guess.
#
#   ImageLicence.derive(copyright: 'Taken Mar 14, 2022 by Jane Doe (cc-by-sa)',
#                       image_url: 'https://bs.plantnet.org/image/o/ab12')
#   # => { licence: 'CC-BY-SA', licence_url: 'https://creativecommons.org/licenses/by-sa/',
#   #      author: 'Jane Doe', commercial_use_allowed: true,
#   #      thumbnail_url: 'https://bs.plantnet.org/image/s/ab12' }
#
# Sources, as found in production (2026-10-13 dump, 557,771 images):
#
# - Pl@ntNet (bs.plantnet.org, 356,411): the crawler writes
#   "Taken <Mon D, YYYY> by <author> (<licence code>)" from the API's `date`,
#   `author` and `license` fields. Pl@ntNet states "CC BY-SA" without a
#   version (my.plantnet.org/doc/references/using-images), so the ids carry
#   no version either and the URL is the unversioned Creative Commons page.
#   "public" is not documented by Pl@ntNet: it stays unknown (nil). An author
#   made of digits only ("1", 463 images) is an account id, not a name.
# - Kew / POWO (d2seqvvyy3b8p2.cloudfront.net and storage.googleapis.com/
#   powop-assets, 201,360): the crawler writes one fixed copyright line for
#   every image, all rights reserved by the Board of Trustees of RBG Kew. The
#   photographer is not recorded.
#
# Thumbnails are only built on hosts verified to serve them (2026-10-14):
# Pl@ntNet /image/s/<id> (150x150, ~10 KB, next to /m/ 600x600 and the
# original /o/) and POWO assets <name>_thumbnail.jpg (400 px). The Kew
# CloudFront originals have no thumbnail (…_thumbnail.jpg answers 403).
module ImageLicence
  ALL_RIGHTS_RESERVED = 'LicenseRef-All-Rights-Reserved'.freeze

  TERMS = {
    'cc-by' => { licence: 'CC-BY', licence_url: 'https://creativecommons.org/licenses/by/', commercial_use_allowed: true },
    'cc-by-sa' => { licence: 'CC-BY-SA', licence_url: 'https://creativecommons.org/licenses/by-sa/', commercial_use_allowed: true },
    'cc-by-nc' => { licence: 'CC-BY-NC', licence_url: 'https://creativecommons.org/licenses/by-nc/', commercial_use_allowed: false },
    'cc-by-nc-sa' => { licence: 'CC-BY-NC-SA', licence_url: 'https://creativecommons.org/licenses/by-nc-sa/', commercial_use_allowed: false },
    # The GPL lets anyone use the work commercially; the version is not given.
    'gpl' => { licence: 'GPL', licence_url: nil, commercial_use_allowed: true },
    '©' => { licence: ALL_RIGHTS_RESERVED, licence_url: nil, commercial_use_allowed: false }
  }.freeze

  UNKNOWN_TERMS = { licence: nil, licence_url: nil, commercial_use_allowed: nil }.freeze

  PLANTNET_COPYRIGHT = /\ATaken [A-Z][a-z]{2} \d{1,2}, \d{4} by (?<author>.+) \((?<code>cc-by-nc-sa|cc-by-nc|cc-by-sa|cc-by|gpl|public|©)\)\z/

  KEW_COPYRIGHT = '© copyright of the Board of Trustees of the Royal Botanic Gardens, Kew.'.freeze

  PLANTNET_ORIGINAL = %r{\Ahttps://bs\.plantnet\.org/image/o/(?<id>[0-9a-f]+)\z}
  POWO_ASSET_FULLSIZE = %r{\A(?<base>https://storage\.googleapis\.com/powop-assets/.+)_fullsize\.jpg\z}

  FIELDS = %i[licence licence_url author commercial_use_allowed thumbnail_url].freeze

  def self.derive(copyright:, image_url:)
    terms_from(copyright.to_s.strip).merge(thumbnail_url: thumbnail_url(image_url.to_s))
  end

  def self.terms_from(copyright)
    if (m = PLANTNET_COPYRIGHT.match(copyright))
      (TERMS[m[:code]] || UNKNOWN_TERMS).merge(author: author(m[:author]))
    elsif copyright == KEW_COPYRIGHT
      TERMS['©'].merge(author: nil)
    else
      UNKNOWN_TERMS.merge(author: nil)
    end
  end

  def self.author(raw)
    name = raw.strip
    name.empty? || name.match?(/\A\d+\z/) ? nil : name
  end

  def self.thumbnail_url(image_url)
    if (m = PLANTNET_ORIGINAL.match(image_url))
      "https://bs.plantnet.org/image/s/#{m[:id]}"
    elsif (m = POWO_ASSET_FULLSIZE.match(image_url))
      "#{m[:base]}_thumbnail.jpg"
    end
  end

  private_class_method :terms_from, :author
end
