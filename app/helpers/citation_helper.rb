# Builds the canonical citation for Trefle (#321): the plain text, APA and
# BibTeX variants the /citation page renders, and CITATION.cff mirrors.
# LICENCE is the single source of truth for the licence naming the data
# (decided in #285), reused here and, once #319 lands, by the API's
# meta.citation block. The DOI is *not* part of it: it comes from
# TREFLE_DOI, resolved per-request in #citation_doi so that setting the env
# var (once the Zenodo deposit in #322 exists) takes effect without
# requiring a reload.
module CitationHelper
  LICENCE = {
    name: 'CC-BY-4.0',
    url: 'https://creativecommons.org/licenses/by/4.0/'
  }.freeze

  def citation_year
    Date.current.year
  end

  def citation_doi
    ENV['TREFLE_DOI'].presence
  end

  def citation_url
    citation_doi ? "https://doi.org/#{citation_doi}" : 'https://trefle.io'
  end

  # The one fact set every format below renders from, so they cannot drift.
  def citation_fields
    {
      title: 'Trefle: a global plants API',
      year: citation_year,
      url: citation_url,
      doi: citation_doi,
      licence: LICENCE[:name]
    }
  end

  def citation_text
    f = citation_fields
    "Trefle (#{f[:year]}). #{f[:title]}. #{f[:url]} — data licensed #{f[:licence]}."
  end

  def citation_apa
    f = citation_fields
    "Trefle. (#{f[:year]}). #{f[:title]} [Data set]. #{f[:url]}"
  end

  def citation_bibtex
    f = citation_fields
    entries = [
      ['title', f[:title]],
      ['author', '{Trefle}'],
      ['year', f[:year].to_s],
      ['url', f[:url]],
      ['note', "Data licensed #{f[:licence]}"]
    ]
    entries << ['doi', f[:doi]] if f[:doi]

    body = entries.map {|key, value| "  #{key} = {#{value}}" }.join(",\n")
    "@misc{trefle#{f[:year]},\n#{body}\n}"
  end
end
