# Where each value of a species comes from: its facts grouped by attribute,
# set against the value the species record actually shows. Read-only; shared
# by the back office and the public "Data sources" page.
class SpeciesProvenance

  # One attribute of the species.
  #   shown:   the value the record carries (nil when the column is empty),
  #            or :none when the attribute is not a column of the record
  #   facts:   its facts, active first, strongest source first
  #   state:   :sourced    an active fact holds the shown value
  #            :disputed   the record shows a value no active fact holds, and
  #                        active facts claim another one
  #            :unsourced  the record shows a value no fact accounts for
  #                        (imported before provenance was recorded)
  #            :unshown    facts exist but the record carries no such value
  Attribute = Struct.new(:name, :category, :unit, :shown, :facts, :state, keyword_init: true) do
    def active_facts = facts.select(&:active_status?)
    def history_facts = facts.reject(&:active_status?)

    # The active fact holding the shown value (the strongest one when several
    # sources agree).
    def shown_fact
      active_facts.find {|f| SpeciesProvenance.same_value?(f.value, shown) }
    end

    # Active claims that disagree with the shown value.
    def disagreeing_facts
      return [] if %i[none].include?(shown) || shown.nil?

      active_facts.reject {|f| SpeciesProvenance.same_value?(f.value, shown) }
    end
  end

  STATES = %i[sourced disputed unsourced unshown].freeze

  attr_reader :species

  def initialize(species)
    @species = species
  end

  def facts
    @facts ||= species.species_facts.to_a
  end

  # Every attribute that has a fact or a filled arbitrated column, ordered by
  # trait category then name.
  def attributes
    @attributes ||= begin
      by_name = facts.group_by(&:attribute_name)
      names = (by_name.keys + filled_arbitrated_fields).uniq
      names.map {|name| build(name, by_name[name] || []) }
        .sort_by {|a| [category_rank(a.category), a.name] }
    end
  end

  def counts
    attributes.group_by(&:state).transform_values(&:size)
  end

  def sources
    facts.select(&:active_status?).map(&:source).uniq.sort_by {|s| Traits.priority_index(s) }
  end

  # "1600" and 1600.0, "apr, may" and {:may, :apr} are the same value.
  def self.same_value?(fact_value, shown)
    return false if shown.nil? || shown == :none

    a = normalize(fact_value)
    b = normalize(shown)
    if a.is_a?(BigDecimal) && b.is_a?(BigDecimal)
      a.round(6) == b.round(6)
    else
      a.to_s == b.to_s
    end
  end

  NUMBER = /\A-?\d+(\.\d+)?\z/

  def self.normalize(value)
    value = value.to_a if value.respond_to?(:to_a) && !value.is_a?(String) && !value.is_a?(Hash) && !value.nil?
    return value.map {|v| v.to_s.strip.downcase }.sort.join(', ') if value.is_a?(Array)

    string = value.to_s.strip
    return BigDecimal(string) if string.match?(NUMBER)
    return string.split(/\s*,\s*/).map(&:downcase).sort.join(', ') if string.include?(',')

    string.downcase
  end

  private

  def build(name, facts)
    sorted = facts.sort_by {|f| [f.active_status? ? 0 : 1, Traits.priority_index(f.source, name), -f.id] }
    attribute = Attribute.new(
      name: name,
      category: Traits.field(name)&.dig('category'),
      unit: Traits.field(name)&.dig('unit'),
      shown: shown_value(name),
      facts: sorted
    )
    attribute.state = state_of(attribute)
    attribute
  end

  # The record value, nil when empty, :none when not a column of the record.
  def shown_value(name)
    return :none unless species.has_attribute?(name)

    value = species.public_send(name)
    return nil unless Traits.filled?(name, value)
    return nil if value.respond_to?(:to_a) && !value.is_a?(String) && value.to_a.empty?

    value
  end

  def state_of(attribute)
    return :unshown if attribute.shown.nil? || attribute.shown == :none
    return :sourced if attribute.shown_fact

    attribute.active_facts.any? ? :disputed : :unsourced
  end

  def filled_arbitrated_fields
    Traits.arbitrated_fields.select do |name|
      next false if Traits.field(name)&.dig('category') == 'media'

      species.has_attribute?(name) && Traits.filled?(name, species[name])
    end
  end

  CATEGORY_ORDER = %w[core descriptive morphology phenology ecology cultivation media raw usda_legacy derived deprecated].freeze

  def category_rank(category)
    CATEGORY_ORDER.index(category) || CATEGORY_ORDER.size
  end
end
