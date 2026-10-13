# The upstream sources a citation of Trefle has to co-cite, derived from the
# data: a source is listed when records in the database actually come from
# it (taxonomy links in foreign_sources_plants, trait claims in
# species_facts), with its licence from foreign_sources. A source connected
# later shows up on its own; one whose last record is gone drops out.
#
# The reference text is the source's peer-reviewed or recommended citation
# when we know it (REFERENCES, matched by slug), else the citation template
# stored on the ForeignSource row, else its name and URL.
#
# Counting ~2 million rows is not free, so the list is cached per dataset
# version: it can only change when a data run has written.
class CitationSources

  # Above this many records, a source is a required co-citation; below it,
  # it is listed as a minor contributor (a handful of hand-sourced values).
  MAJOR_THRESHOLD = 1_000

  # Internal bookkeeping rows, not an upstream source.
  INTERNAL_SLUGS = %w[merged_from_synonym].freeze

  WCVP = {
    key: 'govaerts2021wcvp',
    type: :article,
    authors: ['Govaerts, Rafaël', 'Nic Lughadha, Eimear', 'Black, Nicholas', 'Turner, Robert', 'Paton, Alan'],
    title: 'The World Checklist of Vascular Plants, a continuously updated resource for exploring global plant diversity',
    journal: 'Scientific Data',
    year: 2021,
    volume: '8',
    pages: '215',
    doi: '10.1038/s41597-021-00997-6'
  }.freeze

  TRY = {
    key: 'kattge2020try',
    type: :article,
    authors: ['Kattge, Jens', 'Bönisch, Gerhard', 'Díaz, Sandra', 'Lavorel, Sandra', 'Prentice, Iain Colin', 'others'],
    title: 'TRY plant trait database – enhanced coverage and open access',
    journal: 'Global Change Biology',
    year: 2020,
    volume: '26',
    number: '1',
    pages: '119--188',
    doi: '10.1111/gcb.14904'
  }.freeze

  # Recommended citations, by ForeignSource slug. `works` are the structured
  # references rendered in BibTeX and RIS as well.
  REFERENCES = {
    'powo' => {
      text: 'Govaerts, R., Nic Lughadha, E., Black, N., Turner, R. & Paton, A. (2021). ' \
            'The World Checklist of Vascular Plants, a continuously updated resource for exploring global plant diversity. ' \
            'Scientific Data 8, 215. https://doi.org/10.1038/s41597-021-00997-6 ; ' \
            'and POWO, Plants of the World Online, facilitated by the Royal Botanic Gardens, Kew. https://powo.science.kew.org/',
      works: [WCVP]
    },
    'try' => {
      text: 'Kattge, J. et al. (2020). TRY plant trait database – enhanced coverage and open access. ' \
            'Global Change Biology 26, 119–188. https://doi.org/10.1111/gcb.14904 ' \
            '— credit the TRY initiative and its contributing datasets.',
      works: [TRY]
    },
    'gbif' => {
      text: 'GBIF Secretariat. GBIF Backbone Taxonomy. Checklist dataset https://doi.org/10.15468/39omei accessed via GBIF.org.'
    },
    'WFO' => {
      text: 'WFO. World Flora Online. Published on the Internet; http://www.worldfloraonline.org.'
    },
    'IPNI' => {
      text: 'IPNI. International Plant Names Index. Published on the Internet http://www.ipni.org, ' \
            'The Royal Botanic Gardens, Kew, Harvard University Herbaria & Libraries and Australian National Herbarium.'
    },
    'plantnet' => {
      text: 'Pl@ntNet, https://plantnet.org — each image keeps the author and licence returned with it (the `copyright` field of the API).'
    },
    'usda' => {
      text: 'USDA, NRCS. The PLANTS Database. National Plant Data Team, Greensboro, NC, USA. https://plants.usda.gov'
    }
  }.freeze

  Source = Struct.new(:slug, :name, :url, :licence, :licence_url, :records, :reference, :works, keyword_init: true) do
    def major?
      records >= MAJOR_THRESHOLD
    end
  end

  def self.all
    Rails.cache.fetch(['citation_sources/v1', DatasetVersion.current_version], expires_in: 1.day) { compute }
  end

  def self.major
    all.select(&:major?)
  end

  def self.minor
    all.reject(&:major?)
  end

  # The structured works of the major sources, for BibTeX and RIS.
  def self.works
    major.flat_map(&:works).compact.uniq {|work| work[:key] }
  end

  def self.compute
    links = ForeignSourcesPlant.group(:foreign_source_id).count
    facts = SpeciesFact.group(:source).count.transform_keys(&:downcase)

    sources = ForeignSource.where.not(slug: INTERNAL_SLUGS).filter_map do |source|
      records = links.fetch(source.id, 0) + facts.fetch(source.slug.to_s.downcase, 0)
      build(source, records) unless records.zero?
    end
    sources.sort_by {|source| -source.records }
  end

  def self.build(source, records)
    known = REFERENCES[source.slug] || {}
    Source.new(
      slug: source.slug, name: source.name, url: source.url,
      licence: source.licence, licence_url: source.licence_url,
      records: records,
      reference: known[:text] || source.copyright_template.presence || [source.name, source.url.presence].compact.join('. '),
      works: known[:works] || []
    )
  end

end
