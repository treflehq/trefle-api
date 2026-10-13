module SpeciesFactsHelper
  UNIT_LABELS = { 'cm' => 'cm', 'mm' => 'mm', 'deg_c' => '°C', 'deg_f' => '°F', 'ph' => 'pH' }.freeze

  STATE_TAGS = {
    sourced: ['is-success is-light', 'Sourced', 'A source gives the value shown.'],
    disputed: ['is-warning', 'Differs from sources', 'The value shown is not the one the sources give.'],
    unsourced: ['is-light', 'Source not recorded', 'Imported before sources were recorded value by value.'],
    unshown: ['is-white', 'Not on the record', 'A source gives a value the record does not show.']
  }.freeze

  SOURCE_NAMES = {
    'community' => 'Community (reviewed)',
    'legacy' => 'Earlier Trefle data',
    'merged_from_synonym' => 'Merged from a synonym record',
    'powo' => 'POWO / WCVP (Kew)',
    'wfo' => 'World Flora Online',
    'gbif' => 'GBIF',
    'try' => 'TRY Plant Trait Database',
    'pfaf' => 'Plants For A Future',
    'usda' => 'USDA PLANTS',
    'flora_iberica' => 'Flora iberica',
    'flora_of_north_america' => 'Flora of North America',
    'missouri_botanical_garden' => 'Missouri Botanical Garden',
    'treesandshrubsonline' => 'Trees and Shrubs Online'
  }.freeze

  def fact_attribute_label(name)
    name.to_s.sub(/_(cm|mm|deg_c|deg_f)\z/, '').humanize
  end

  # A fact value as read: numbers rounded, with their unit.
  def fact_value(fact, unit = fact.unit)
    text = if fact.value_numeric
             number_with_precision(fact.value_numeric, precision: 2, strip_insignificant_zeros: true, delimiter: '')
           else
             fact.value.to_s
           end
    with_unit(text, unit)
  end

  # The value the record shows, in the same form as its facts.
  def provenance_shown_value(attribute)
    return tag.span('—', class: 'has-text-grey-light', title: 'Not a field of the record') if attribute.shown == :none
    return tag.em('empty', class: 'has-text-grey') if attribute.shown.nil?

    value = attribute.shown
    value = value.to_a.map(&:to_s).join(', ') if value.respond_to?(:to_a) && !value.is_a?(String)
    value = number_with_precision(value, precision: 2, strip_insignificant_zeros: true, delimiter: '') if value.is_a?(Numeric)
    with_unit(value.to_s, attribute.unit)
  end

  def provenance_state_tag(state)
    css, label, title = STATE_TAGS.fetch(state)
    tag.span(label, class: "tag #{css}", title: title)
  end

  def fact_source_name(slug)
    SOURCE_NAMES[slug.to_s.downcase] || slug.to_s.humanize
  end

  # The source, linked to the record it was read from when we know its URL.
  def fact_source(fact)
    name = fact_source_name(fact.source)
    name = "#{name} (#{fact.source_record_id})" if fact.source == 'merged_from_synonym' && fact.source_record_id.present?
    url = fact.source_url.presence || fact_record_url(fact)
    url ? link_to(name, url, target: '_blank', rel: 'noopener') : name
  end

  def fact_record_url(fact)
    id = fact.source_record_id.to_s
    case fact.source
    when 'gbif' then "https://www.gbif.org/species/#{id}" if id.match?(/\A\d+\z/)
    when 'powo' then "https://powo.science.kew.org/taxon/#{id}" if id.start_with?('urn:lsid:ipni.org:names:')
    when 'wfo' then "https://www.worldfloraonline.org/taxon/#{id}" if id.start_with?('wfo-')
    when 'try' then 'https://www.try-db.org/TryWeb/Home.php'
    end
  end

  # "Measured · 53 observations · 2026-10-09"
  def fact_evidence(fact)
    [
      fact.evidence_type.to_s.humanize,
      (pluralize(fact.n_observations, 'observation') if fact.n_observations.to_i.positive?),
      (fact.observed_at || fact.created_at)&.to_date&.iso8601
    ].compact.join(' · ')
  end

  private

  def with_unit(text, unit)
    label = UNIT_LABELS[unit.to_s]
    return text if label.nil? || text.blank?

    label == 'pH' ? "pH #{text}" : "#{text} #{label}"
  end
end
