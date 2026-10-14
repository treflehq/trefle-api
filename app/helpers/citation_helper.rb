# Builds the canonical citation for Trefle (#321): the plain text, APA,
# BibTeX and RIS variants the /citation page renders, and CITATION.cff
# mirrors. LICENCE is the single source of truth for the licence naming the
# data (decided in #285), reused by the API root. The DOI is *not* part of
# it: it comes from TREFLE_DOI, resolved per-request in #citation_doi so that
# setting the env var (once the Zenodo deposit in #322 exists) takes effect
# without requiring a reload.
#
# A citation also states the data version (DatasetVersion, derived from the
# data journal) and the date the data was accessed: the version pins the last
# bulk data operation, the access date covers the community corrections
# accepted one by one since. The upstream sources to co-cite come from the
# data as well (CitationSources).
module CitationHelper
  LICENCE = {
    name: 'CC-BY-4.0',
    url: 'https://creativecommons.org/licenses/by/4.0/'
  }.freeze

  # Left for the citing author to fill in: the day they queried the API.
  ACCESS_DATE_PLACEHOLDER = 'YYYY-MM-DD'.freeze

  def citation_year
    Date.current.year
  end

  def citation_doi
    ENV['TREFLE_DOI'].presence
  end

  def citation_url
    citation_doi ? "https://doi.org/#{citation_doi}" : 'https://trefle.io'
  end

  def citation_version
    DatasetVersion.current_version
  end

  # The one fact set every format below renders from, so they cannot drift.
  def citation_fields
    {
      title: 'Trefle: a global plants API',
      year: citation_year,
      url: citation_url,
      doi: citation_doi,
      version: citation_version,
      accessed: ACCESS_DATE_PLACEHOLDER,
      licence: LICENCE[:name]
    }
  end

  def citation_text
    f = citation_fields
    version = f[:version] ? ", data version #{f[:version]}" : ''
    "Trefle (#{f[:year]}). #{f[:title]}#{version}. #{f[:url]} (accessed #{f[:accessed]}) — data licensed #{f[:licence]}."
  end

  def citation_apa
    f = citation_fields
    version = f[:version] ? " (Version #{f[:version]})" : ''
    "Trefle. (#{f[:year]}). #{f[:title]}#{version} [Data set]. Retrieved #{f[:accessed]}, from #{f[:url]}"
  end

  def citation_bibtex
    f = citation_fields
    CitationFormats.bibtex('misc', "trefle#{f[:year]}", [
                             ['title', f[:title]],
                             ['author', '{Trefle}'],
                             ['year', f[:year].to_s],
                             ['version', f[:version]],
                             ['url', f[:url]],
                             ['urldate', f[:accessed]],
                             ['note', "Data licensed #{f[:licence]}"],
                             ['doi', f[:doi]]
                           ])
  end

  def citation_ris
    f = citation_fields
    CitationFormats.ris([
                          %w[TY DATA], %w[AU Trefle], ['TI', f[:title]], ['PY', f[:year].to_s],
                          ['ET', f[:version] && "Version #{f[:version]}"],
                          ['UR', f[:url]], ['Y2', f[:accessed]], ['DO', f[:doi]],
                          ['N1', "Data licensed #{f[:licence]}"]
                        ])
  end

  # The upstream sources whose records Trefle serves, most used first.
  def citation_sources
    CitationSources.major
  end

  def citation_minor_sources
    CitationSources.minor
  end

  # Plain text: Trefle, then each required co-citation.
  def citation_text_with_sources
    [citation_text, *citation_sources.map(&:reference)].join("\n\n")
  end

  # BibTeX: Trefle, then the co-citations that are published works.
  def citation_bibtex_with_sources
    [citation_bibtex, *CitationSources.works.map {|work| CitationFormats.bibtex_work(work) }].join("\n\n")
  end

  def citation_ris_with_sources
    [citation_ris, *CitationSources.works.map {|work| CitationFormats.ris_work(work) }].join("\n\n")
  end
end
